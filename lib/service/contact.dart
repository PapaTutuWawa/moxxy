import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactWrapper {
  const ContactWrapper(this.id, this.jid);
  final String id;
  final String jid;
}

class ContactsService {
  ContactsService() : _log = Logger('ContactsService') {
    // NOTE: Apparently, this means that if false, contacts that are in 0 groups
    //       are not returned.
    FlutterContacts.config.includeNonVisibleOnAndroid = true;
  }
  final Logger _log;

  bool enabled = false;
  
  /// JID -> Id
  Map<String, String>? _contactIds;
  /// Contact ID -> Display name from the contact or null if we cached that there is none
  final Map<String, String?> _contactDisplayNames = {};

  Future<void> init() async {
    if (await _canUseContactIntegration()) {
      enableDatabaseListener();
    }
  }

  /// Enable listening to contact database events
  void enableDatabaseListener() {
    FlutterContacts.addListener(_onContactsDatabaseUpdate);
  }

  /// Disable listening to contact database events
  void disableDatabaseListener() {
    FlutterContacts.removeListener(_onContactsDatabaseUpdate);
  }
  
  Future<List<ContactWrapper>> fetchContactsWithJabber() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    _log.finest('Got ${contacts.length} contacts');

    final jabberContacts = List<ContactWrapper>.empty(growable: true);
    for (final c in contacts) {
      final index = c.socialMedias
        .indexWhere((s) => s.label == SocialMediaLabel.jabber);
      if (index == -1) continue;

      jabberContacts.add(
        ContactWrapper(c.id, c.socialMedias[index].userName),
      );
    }
    _log.finest('${jabberContacts.length} contacts have an XMPP address');

    return jabberContacts;
  }

  Future<void> _onContactsDatabaseUpdate() async {
    _log.finest('Got contacts database update');
    await scanContacts();
  }

  /// Checks if we a) have the permission to access the contact list and b) if the
  /// user wants to use this integration.
  /// Returns true if we can proceed with accessing the contact list. False, if not.
  Future<bool> _canUseContactIntegration() async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    if (!prefs.enableContactIntegration) {
      _log.finest('_canUseContactIntegration: Returning false since enableContactIntegration is false');
      return false;
    }

    final permission = await Permission.contacts.status;
    if (permission == PermissionStatus.denied) {
      _log.finest("_canUseContactIntegration: Returning false since we don't have the contacts permission");
      return false;
    }

    return true;
  }
  
  Future<Map<String, String>> _getContactIds() async {
    if (_contactIds != null) return _contactIds!;

    _contactIds = await GetIt.I.get<DatabaseService>().getContactIds();
    return _contactIds!;
  }

  /// Queries the contact list, if enabled and allowed, and returns the contact's
  /// display name.
  ///
  /// [id] is the id of the contact. A null value indicates that there is no
  /// contact and null will be returned immediately.
  Future<String?> getContactDisplayName(String? id) async {
    if (id == null ||
        !(await _canUseContactIntegration())) return null;
    if (_contactDisplayNames.containsKey(id)) return _contactDisplayNames[id];

    final result = await FlutterContacts.getContact(
      id,
      withThumbnail: false,
    );
    _contactDisplayNames[id] = result?.displayName;
    return result?.displayName;
  }
  
  Future<String?> getContactIdForJid(String jid) async {
    if (!(await _canUseContactIntegration())) return null;

    return (await _getContactIds())[jid];
  }
  
  Future<void> scanContacts() async {
    final db = GetIt.I.get<DatabaseService>();
    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final contacts = await fetchContactsWithJabber();
    final knownContactIds = await _getContactIds();

    for (final id in knownContactIds.values) {
      final index = contacts.indexWhere((c) => c.id == id);
      if (index != -1) continue;

      await db.removeContactId(id);
      _contactIds!.remove(knownContactIds[id]);
    }

    final modifiedRosterItems = List<RosterItem>.empty(growable: true);
    for (final contact in contacts) {
      if (!knownContactIds.containsKey(contact.jid)) {
        await db.addContactId(contact.id, contact.jid);
        _contactIds![contact.jid] = contact.id;
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
      } else {
        _log.finest('Found no conversation with jid ${contact.jid}');
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
