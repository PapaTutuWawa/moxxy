import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactWrapper {
  const ContactWrapper(this.id, this.jid, this.displayName, this.thumbnail);
  final String id;
  final String jid;
  final String displayName;
  final Uint8List? thumbnail;
}

class ContactsService {
  ContactsService() {
    // NOTE: Apparently, this means that if false, contacts that are in 0 groups
    //       are not returned.
    FlutterContacts.config.includeNonVisibleOnAndroid = true;
  }

  /// Logger.
  final Logger _log = Logger('ContactsService');
  
  /// JID -> Id.
  Map<String, String>? _contactIds;

  /// Contact ID -> Display name from the contact or null if we cached that there is
  /// none
  final Map<String, String?> _contactDisplayNames = {};

  Future<void> initialize() async {
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

  Future<void> _onContactsDatabaseUpdate() async {
    _log.finest('Got contacts database update');
    await scanContacts();
  }

  /// Queries the contact list for contacts that include a XMPP URI.
  Future<List<ContactWrapper>> _fetchContactsWithJabber() async {
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: true,
    );
    _log.finest('Got ${contacts.length} contacts');

    final jabberContacts = List<ContactWrapper>.empty(growable: true);
    for (final c in contacts) {
      final index = c.socialMedias
        .indexWhere((s) => s.label == SocialMediaLabel.jabber);
      if (index == -1) continue;

      jabberContacts.add(
        ContactWrapper(
          c.id,
          c.socialMedias[index].userName,
          c.displayName,
          c.thumbnail,
        ),
      );
    }
    _log.finest('${jabberContacts.length} contacts have an XMPP address');

    return jabberContacts;
  }

  /// Checks whether the contact integration is enabled by the user in the preferences.
  /// Returns true if that is the case. If not, returns false.
  Future<bool> isContactIntegrationEnabled() async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    return prefs.enableContactIntegration;
  }
  
  /// Checks if we a) have the permission to access the contact list and b) if the
  /// user wants to use this integration.
  /// Returns true if we can proceed with accessing the contact list. False, if not.
  Future<bool> _canUseContactIntegration() async {
    if (!(await isContactIntegrationEnabled())) {
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

  /// Queries the database for the mapping of JID -> Contact ID. The result is
  /// cached after the first call.
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

  /// Returns the contact Id for the JID [jid]. If either the contact integration is
  /// disabled, not possible (due to missing permissions) or there is no contact with
  /// [jid] as their Jabber attribute, returns null.
  Future<String?> getContactIdForJid(String jid) async {
    if (!(await _canUseContactIntegration())) return null;

    return (await _getContactIds())[jid];
  }

  /// Returns the path to the avatar file for the contact with JID [jid] as their
  /// Jabber attribute. If either the contact integration is disabled, not possible
  /// (due to missing permissions) or there is no contact with [jid] as their Jabber
  /// attribute, returns null.
  Future<String?> getProfilePicturePathForJid(String jid) async {
    final id = await getContactIdForJid(jid);
    if (id == null) return null;

    final avatarPath = await getContactProfilePicturePath(id);
    return File(avatarPath).existsSync() ?
      avatarPath :
      null;
  }

  Future<void> scanContacts() async {
    final db = GetIt.I.get<DatabaseService>();
    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final contacts = await _fetchContactsWithJabber();
    // JID -> Id
    final knownContactIds = await _getContactIds();
    // Id -> JID
    final knownContactIdsReverse = knownContactIds
      .map((key, value) => MapEntry(value, key));
    final modifiedRosterItems = List<RosterItem>.empty(growable: true);
    final addedRosterItems = List<RosterItem>.empty(growable: true);
    final removedRosterItems = List<String>.empty(growable: true);

    for (final id in List<String>.from(knownContactIds.values)) {
      final index = contacts.indexWhere((c) => c.id == id);
      if (index != -1) continue;

      final jid = knownContactIdsReverse[id]!;
      await db.removeContactId(id);
      _contactIds!.remove(knownContactIdsReverse[id]);

      // Remove the avatar file, if it existed
      final avatarPath = await getContactProfilePicturePath(id);
      final avatarFile = File(avatarPath);
      if (avatarFile.existsSync()) {
        unawaited(avatarFile.delete());
      }

      // Remove the contact attributes from the conversation, if it existed
      final conversation = await cs.createOrUpdateConversation(
        jid,
        update: (c) async {
          return cs.updateConversation(
            jid,
            contactId: null,
            contactAvatarPath: null,
            contactDisplayName: null,
          );
        },
      );
      if (conversation != null) {
        sendEvent(
          ConversationUpdatedEvent(
            conversation: conversation,
          ),
        );
      }

      // Remove the contact attributes from the roster item, if it existed
      final r = await rs.getRosterItemByJid(jid);
      if (r != null) {
        if (r.pseudoRosterItem) {
          _log.finest('Removing pseudo roster item $jid');
          await rs.removeRosterItem(r.id);
          removedRosterItems.add(jid);
        } else {
          final newRosterItem = await rs.updateRosterItem(
            r.id,
            contactId: null,
            contactAvatarPath: null,
            contactDisplayName: null,
          );
          modifiedRosterItems.add(newRosterItem);
        }
      }
    }

    for (final contact in contacts) {
      // Add the ID to the cache and the database if it does not already exist
      if (!knownContactIds.containsKey(contact.jid)) {
        await db.addContactId(contact.id, contact.jid);
        _contactIds![contact.jid] = contact.id;
      }

      // Store the avatar image
      // NOTE: We do not check if the file already exists since this function may also
      //       be triggered by the contact database listener. That listener fires when
      //       a change happened, without telling us exactly what happened. So, we
      //       just overwrite it.
      final contactAvatarPath = await getContactProfilePicturePath(contact.id);
      if (contact.thumbnail != null) {
        final file = File(contactAvatarPath);
        await file.writeAsBytes(contact.thumbnail!);
      }

      // Update a possibly existing conversation
      final conversation = await cs.createOrUpdateConversation(
        contact.jid,
        update: (c) async {
          return cs.updateConversation(
            contact.jid,
            contactId: contact.id,
            contactAvatarPath: contactAvatarPath,
            contactDisplayName: contact.displayName,           
          );
        },
      );
      if (conversation != null) {
        sendEvent(
          ConversationUpdatedEvent(
            conversation: conversation,
          ),
        );
      }

      // Update a possibly existing roster item
      final r = await rs.getRosterItemByJid(contact.jid);
      if (r != null) {
        final newRosterItem = await rs.updateRosterItem(
          r.id,
          contactId: contact.id,
          contactAvatarPath: contactAvatarPath,
          contactDisplayName: contact.displayName,
        );
        modifiedRosterItems.add(newRosterItem);
      } else {
        final newRosterItem = await rs.addRosterItemFromData(
          '',
          '',
          contact.jid,
          contact.jid.split('@').first,
          'none',
          'none',
          true,
          contact.id,
          contactAvatarPath,
          contact.displayName,
        );
        addedRosterItems.add(newRosterItem);
      }
    }

    if (addedRosterItems.isNotEmpty ||
        modifiedRosterItems.isNotEmpty ||
        removedRosterItems.isNotEmpty) {
      sendEvent(
        RosterDiffEvent(
          added: addedRosterItems,
          modified: modifiedRosterItems,
          removed: removedRosterItems,
        ),
      );
    }
  }
}
