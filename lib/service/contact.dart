import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/roster.dart';

class ContactWrapper {
  const ContactWrapper(this.title, this.id, this.jid);
  final String title;
  final String id;
  final String jid;
}

class ContactsService {
  ContactsService() : _log = Logger('ContactsService') {
    // NOTE: Apparently, this means that if false, contacts that are in 0 groups
    //       are not returned.
    FlutterContacts.config.includeNonVisibleOnAndroid = true;

    // Allow us to react to database changes
    FlutterContacts.addListener(_onContactsDatabaseUpdate);
  }
  final Logger _log;

  List<String>? _contactIds;
  
  Future<List<ContactWrapper>> fetchContactsWithJabber() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    _log.finest('Got ${contacts.length} contacts');

    final jabberContacts = List<ContactWrapper>.empty(growable: true);
    for (final c in contacts) {
      final index = c.socialMedias
        .indexWhere((s) => s.label == SocialMediaLabel.jabber);
      if (index == -1) continue;

      jabberContacts.add(
        ContactWrapper(
          '${c.name.first} ${c.name.last}',
          c.id,
          c.socialMedias[index].userName,
        ),
      );
    }
    _log.finest('${jabberContacts.length} contacts have an XMPP address');

    return jabberContacts;
  }

  Future<void> _onContactsDatabaseUpdate() async {
    _log.finest('Got contacts database update');
  }

  Future<List<String>> _getContactIds() async {
    if (_contactIds != null) return _contactIds!;

    _contactIds = List<String>.from(
      await GetIt.I.get<DatabaseService>().getContactIds(),
    );
    return _contactIds!;
  }
  
  Future<void> scanContacts() async {
    final db = GetIt.I.get<DatabaseService>();
    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final contacts = await fetchContactsWithJabber();
    final knownContactIds = await _getContactIds();

    for (final id in knownContactIds) {
      final index = contacts.indexWhere((c) => c.id == id);
      if (index != -1) continue;

      await db.removeContactId(id);
      _contactIds!.remove(id);
    }

    final modifiedRosterItems = List<RosterItem>.empty(growable: true);
    for (final contact in contacts) {
      if (!knownContactIds.contains(contact.id)) {
        await db.addContactId(contact.id);
        _contactIds!.add(contact.id);
      }

      final c = await cs.getConversationByJid(contact.jid);
      if (c != null) {
        final newConv = await cs.updateConversation(
          c.id,
          contactId: contact.id,
        );
        sendEvent(
          ConversationUpdatedEvent(
            conversation: newConv,
          ),
        );
      }

      final r = await rs.getRosterItemByJid(contact.jid);
      if (r != null) {
        final newRosterItem = await rs.updateRosterItem(
          r.id,
          contactId: contact.id,
        );
        modifiedRosterItems.add(newRosterItem);
      } else {
        // TODO(PapaTutuWawa): Create it
      }
    }

    if (modifiedRosterItems.isNotEmpty) {
      sendEvent(
        RosterDiffEvent(
          modified: modifiedRosterItems,
        ),
      );
    }
  }
}
