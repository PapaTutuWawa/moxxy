import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/creation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/database/migrations/0000_xmpp_state.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/state.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:omemo_dart/omemo_dart.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

const databasePasswordKey = 'database_encryption_password';

class DatabaseService {
  
  DatabaseService() : _log = Logger('DatabaseService');
  late Database _db;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ); 
  final Logger _log;

  Future<void> initialize() async {
    final dbPath = path.join(
      await getDatabasesPath(),
      'moxxy.db',
    );

    String key;
    if (await _storage.containsKey(key: databasePasswordKey)) {
      _log.finest('Database encryption key found');
      key = (await _storage.read(key: databasePasswordKey))!;
    } else {
      _log.finest('Database encryption not key found. Generating it...');
      key = randomAlphaNumeric(40, provider: CoreRandomProvider.from(Random.secure()));
      await _storage.write(key: databasePasswordKey, value: key);
      _log.finest('Key generation done...');
    }
    
    _db = await openDatabase(
      dbPath,
      password: key,
      version: 2,
      onCreate: createDatabase,
      onConfigure: configureDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          _log.finest('Running migration for database version 2');
          await upgradeFromV1ToV2(db);
        }
      },
    );

    _log.finest('Database setup done');
  }
  
  /// Loads all conversations from the database and adds them to the state and cache.
  Future<List<Conversation>> loadConversations() async {
    final conversationsRaw = await _db.query('Conversations',
      orderBy: 'lastChangeTimestamp DESC',
    );
    
    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final id = c['id']! as int;

      final sharedMediaRaw = await _db.query(
        'SharedMedia',
        where: 'conversation_id = ?',
        whereArgs: [id],
        orderBy: 'timestamp DESC',
      );
      final rosterItem = await GetIt.I.get<RosterService>()
        .getRosterItemByJid(c['jid']! as String);

      tmp.add(
        Conversation.fromDatabaseJson(
          c,
          rosterItem != null,
          rosterItem?.subscription ?? 'none',
          sharedMediaRaw,
        ),
      );
    }

    _log.finest(tmp.toString());
    
    return tmp;
  }

  /// Load messages for [jid] from the database.
  Future<List<Message>> loadMessagesForJid(String jid) async {
    final rawMessages = await _db.query(
      'Messages',
      where: 'conversationJid = ?',
      whereArgs: [jid],
      orderBy: 'timestamp ASC',
    );

    final messages = List<Message>.empty(growable: true);
    for (final m in rawMessages) {
      Message? quotes;
      if (m['quote_id'] != null) {
        final rawQuote = (await _db.query(
          'Messages',
          where: 'conversationJid = ? AND id = ?',
          whereArgs: [jid, m['quote_id']! as int],
        )).first;
        quotes = Message.fromDatabaseJson(rawQuote, null);
      }

      messages.add(Message.fromDatabaseJson(m, quotes));
    }

    return messages;
  }
  
  /// Updates the conversation with id [id] inside the database.
  Future<Conversation> updateConversation(int id, {
      String? lastMessageBody,
      int? lastChangeTimestamp,
      bool? open,
      int? unreadCounter,
      String? avatarUrl,
      ChatState? chatState,
      bool? muted,
      bool? encrypted,
    }
  ) async {
    final cd = (await _db.query(
      'Conversations',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    final c = Map<String, dynamic>.from(cd);

    final sharedMedia = (await _db.query(
      'SharedMedia',
      where: 'conversation_id = ?',
      whereArgs: [id],
      orderBy: 'timestamp DESC',
    )).map(SharedMedium.fromDatabaseJson);
    
    //await c.sharedMedia.load();
    if (lastMessageBody != null) {
      c['lastMessageBody'] = lastMessageBody;
    }
    if (lastChangeTimestamp != null) {
      c['lastChangeTimestamp'] = lastChangeTimestamp;
    }
    if (open != null) {
      c['open'] = boolToInt(open);
    }
    if (unreadCounter != null) {
      c['unreadCounter'] = unreadCounter;
    }
    if (avatarUrl != null) {
      c['avatarUrl'] = avatarUrl;
    }
    if (muted != null) {
      c['muted'] = boolToInt(muted);
    }
    if (encrypted != null) {
      c['encrypted'] = boolToInt(encrypted);
    }

    await _db.update(
      'Conversations',
      c,
      where: 'id = ?',
      whereArgs: [id],
    );

    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(c['jid']! as String);
    return Conversation.fromDatabaseJson(
      c,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      sharedMedia.map((m) => m.toJson()).toList(),
    );
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  Future<Conversation> addConversationFromData(
    String title,
    String lastMessageBody,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    bool open,
    bool muted,
    bool encrypted,
  ) async {
    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    final conversation = Conversation(
      title,
      lastMessageBody,
      avatarUrl,
      jid,
      unreadCounter,
      lastChangeTimestamp,
      <SharedMedium>[],
      -1,
      open,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      muted,
      encrypted,
      ChatState.gone,
    );

    return conversation.copyWith(
      id: await _db.insert('Conversations', conversation.toDatabaseJson()),
    );
  }

  /// Like [addConversationFromData] but for [SharedMedium].
  Future<SharedMedium> addSharedMediumFromData(String path, int timestamp, int conversationId, { String? mime }) async {
    final s = SharedMedium(
      -1,
      path,
      timestamp,
      mime: mime,
    );

    return s.copyWith(
      id: await _db.insert('SharedMedia', s.toDatabaseJson(conversationId)),
    );
  }
  
  /// Same as [addConversationFromData] but for a [Message].
  Future<Message> addMessageFromData(
    String body,
    int timestamp,
    String sender,
    String conversationJid,
    bool isMedia,
    String sid,
    bool isFileUploadNotification,
    bool encrypted,
    {
      String? srcUrl,
      String? key,
      String? iv,
      String? encryptionScheme,
      String? mediaUrl,
      String? mediaType,
      String? thumbnailData,
      int? mediaWidth,
      int? mediaHeight,
      String? originId,
      String? quoteId,
      String? filename,
      int? errorType,
      int? warningType,
      Map<String, String>? plaintextHashes,
      Map<String, String>? ciphertextHashes,
      bool isDownloading = false,
      bool isUploading = false,
      int? mediaSize,
    }
  ) async {
    var m = Message(
      sender,
      body,
      timestamp,
      sid,
      -1,
      conversationJid,
      isMedia,
      isFileUploadNotification,
      encrypted,
      errorType: errorType,
      warningType: warningType,
      mediaUrl: mediaUrl,
      key: key,
      iv: iv,
      encryptionScheme: encryptionScheme,
      mediaType: mediaType,
      thumbnailData: thumbnailData,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      srcUrl: srcUrl,
      received: false,
      displayed: false,
      acked: false,
      originId: originId,
      filename: filename,
      plaintextHashes: plaintextHashes,
      ciphertextHashes: ciphertextHashes,
      isUploading: isUploading,
      isDownloading: isDownloading,
      mediaSize: mediaSize,
    );

    if (quoteId != null) {
      final quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes == null) {
        _log.warning('Failed to add quote for message with id $quoteId');
      } else {
        m = m.copyWith(quotes: quotes);
      }
    }

    return m.copyWith(
      id: await _db.insert('Messages', m.toDatabaseJson()),
    );
  }

  Future<Message?> getMessageById(int id) async {
    final messagesRaw = await _db.query(
      'Messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;
    return Message.fromDatabaseJson(msg, null);
  }
  
  Future<Message?> getMessageByXmppId(String id, String conversationJid) async {
    final messagesRaw = await _db.query(
      'Messages',
      where: 'conversationJid = ? AND (sid = ? or originId = ?)',
      whereArgs: [conversationJid, id, id],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;
    return Message.fromDatabaseJson(msg, null);
  }
  
  /// Updates the message item with id [id] inside the database.
  Future<Message> updateMessage(int id, {
    String? mediaUrl,
    String? mediaType,
    bool? received,
    bool? displayed,
    bool? acked,
    int? errorType,
    int? warningType,
    bool? isFileUploadNotification,
    String? srcUrl,
    String? key,
    String? iv,
    String? encryptionScheme,
    int? mediaWidth,
    int? mediaHeight,
    bool? isDownloading,
    bool? isUploading,
    int? mediaSize,
    String? originId,
    String? sid,
  }) async {
    final md = (await _db.query(
      'Messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    )).first;
    final m = Map<String, dynamic>.from(md);

    if (mediaUrl != null) {
      m['mediaUrl'] = mediaUrl;
    }
    if (mediaType != null) {
      m['mediaType'] = mediaType;
    }
    if (received != null) {
      m['received'] = boolToInt(received);
    }
    if (displayed != null) {
      m['displayed'] = boolToInt(displayed);
    }
    if (acked != null) {
      m['acked'] = boolToInt(acked);
    }
    if (errorType != null) {
      m['errorType'] = errorType;
    }
    if (warningType != null) {
      m['warningType'] = warningType;
    }
    if (isFileUploadNotification != null) {
      m['isFileUploadNotification'] = boolToInt(isFileUploadNotification);
    }
    if (srcUrl != null) {
      m['srcUrl'] = srcUrl;
    }
    if (mediaWidth != null) {
      m['mediaWidth'] = mediaWidth;
    }
    if (mediaHeight != null) {
      m['mediaHeight'] = mediaHeight;
    }
    if (mediaSize != null) {
      m['mediaSize'] = mediaSize;
    }
    if (key != null) {
      m['key'] = key;
    }
    if (iv != null) {
      m['iv'] = iv;
    }
    if (encryptionScheme != null) {
      m['encryptionScheme'] = encryptionScheme;
    }
    if (isDownloading != null) {
      m['isDownloading'] = boolToInt(isDownloading);
    }
    if (isUploading != null) {
      m['isUploading'] = boolToInt(isUploading);
    }
    if (sid != null) {
      m['sid'] = sid;
    }
    if (originId != null) {
      m['originId'] = originId;
    }

    await _db.update(
      'Messages',
      m,
      where: 'id = ?',
      whereArgs: [id],
    );

    Message? quotes;
    if (m['quote_id'] != null) {
      quotes = await getMessageById(m['quote_id']! as int);
    }
    
    return Message.fromDatabaseJson(m, quotes);
  }
  
  /// Loads roster items from the database
  Future<List<RosterItem>> loadRosterItems() async {
    final items = await _db.query('RosterItems');

    return items.map(RosterItem.fromDatabaseJson).toList();
  }

  /// Removes a roster item from the database and cache
  Future<void> removeRosterItem(int id) async {
    await _db.delete(
      'RosterItems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Create a roster item from data
  Future<RosterItem> addRosterItemFromData(
    String avatarUrl,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    {
      List<String> groups = const [],
    }
  ) async {
    // TODO(PapaTutuWawa): Handle groups
    final i = RosterItem(
      -1,
      avatarUrl,
      avatarHash,
      jid,
      title,
      subscription,
      ask,
      <String>[],
    );

    return i.copyWith(
      id: await _db.insert('RosterItems', i.toDatabaseJson()),
    );
  }

  /// Updates the roster item with id [id] inside the database.
  Future<RosterItem> updateRosterItem(
    int id, {
      String? avatarUrl,
      String? avatarHash,
      String? title,
      String? subscription,
      String? ask,
      List<String>? groups,
    }
  ) async {
    final id_ = (await _db.query(
      'RosterItems',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    )).first;
    final i = Map<String, dynamic>.from(id_);

    if (avatarUrl != null) {
      i['avatarUrl'] = avatarUrl;
    }
    if (avatarHash != null) {
      i['avatarHash'] = avatarHash;
    }
    if (title != null) {
      i['title'] = title;
    }
    /*
    if (groups != null) {
      i.groups = groups;
    }
    */
    if (subscription != null) {
      i['subscription'] = subscription;
    }
    if (ask != null) {
      i['ask'] = ask;
    }

    await _db.update(
      'RosterItems',
      i,
      where: 'id = ?',
      whereArgs: [id],
    );
    return RosterItem.fromDatabaseJson(i);
  }

  Future<PreferencesState> getPreferences() async {
    final preferencesRaw = (await _db.query(preferenceTable))
      .map((preference) {
        switch (preference['type']! as int) {
          case typeInt: return {
            ...preference,
            'value': stringToInt(preference['value']! as String),
          };
          case typeBool: return {
            ...preference,
            'value': stringToBool(preference['value']! as String),
          };
          case typeString:
          default: return preference;
        }
      }).toList();
    final json = <String, dynamic>{};
    for (final preference in preferencesRaw) {
      json[preference['key']! as String] = preference['value'];
    }

    return PreferencesState.fromJson(json);
  }

  Future<void> savePreferences(PreferencesState state) async {
    final stateJson = state.toJson();
    final preferences = stateJson.keys
      .map((key) {
        int type;
        String value;
        if (stateJson[key] is int) {
          type = typeInt;
          value = intToString(stateJson[key]! as int);
        } else if (stateJson[key] is bool) {
          type = typeBool;
          value = boolToString(stateJson[key]! as bool);
        } else {
          type = typeString;
          value = stateJson[key]! as String;
        }

        return {
          'key': key,
          'type': type,
          'value': value,
        };
      });

    final batch = _db.batch();

    for (final preference in preferences) {
      batch.update(
        preferenceTable,
        preference,
        where: 'key = ?',
        whereArgs: [preference['key']],
      );
    }
    
    await batch.commit();
  }

  Future<XmppState> getXmppState() async {
    final json = <String, String?>{};
    for (final row in await _db.query(xmppStateTable)) {
      json[row['key']! as String] = row['value'] as String?;
    }

    return XmppState.fromDatabaseTuples(json);
  }

  Future<void> saveXmppState(XmppState state) async {
    final batch = _db.batch();

    for (final tuple in state.toDatabaseTuples().entries) {
      batch.insert(
        xmppStateTable,
        <String, String?>{ 'key': tuple.key, 'value': tuple.value },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  Future<void> saveRatchet(OmemoDoubleRatchetWrapper ratchet) async {
    final json = await ratchet.ratchet.toJson();
    await _db.insert(
      omemoRatchetsTable,
      {
        ...json,
        'mkskipped': jsonEncode(json['mkskipped']),
        'acknowledged': boolToInt(json['acknowledged']! as bool),
        'jid': ratchet.jid,
        'id': ratchet.id,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OmemoDoubleRatchetWrapper>> loadRatchets() async {
    final results = await _db.query(omemoRatchetsTable);

    return results.map((ratchet) {
      final json = jsonDecode(ratchet['mkskipped']! as String) as List<dynamic>;
      final mkskipped = List<Map<String, dynamic>>.empty(growable: true);
      for (final i in json) {
        final element = i as Map<String, dynamic>;
        mkskipped.add({
          'key': element['key']! as String,
          'public': element['public']! as String,
          'n': element['n']! as int,
        });
      }

      return OmemoDoubleRatchetWrapper(
        OmemoDoubleRatchet.fromJson(
          {
            ...ratchet,
            'acknowledged': intToBool(ratchet['acknowledged']! as int),
            'mkskipped': mkskipped,
          },
        ),
        ratchet['id']! as int,
        ratchet['jid']! as String,
      );
    }).toList();
  }

  Future<Map<RatchetMapKey, BTBVTrustState>> loadTrustCache() async {
    final entries = await _db.query(omemoTrustCacheTable);

    final mapEntries = entries.map<MapEntry<RatchetMapKey, BTBVTrustState>>((entry) {
      // TODO(PapaTutuWawa): Expose this from omemo_dart
      BTBVTrustState state;
      final value = entry['trust']! as int;
      if (value == 1) {
        state = BTBVTrustState.notTrusted;
      } else if (value == 2) {
        state = BTBVTrustState.blindTrust;
      } else if (value == 3) {
        state = BTBVTrustState.verified;
      } else {
        state = BTBVTrustState.notTrusted;
      }

      return MapEntry(
        RatchetMapKey.fromJsonKey(entry['key']! as String),
        state,
      );
    });

    return Map.fromEntries(mapEntries);
  }

  Future<void> saveTrustCache(Map<String, int> cache) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustCacheTable);
    for (final entry in cache.entries) {
      batch.insert(
        omemoTrustCacheTable,
        {
          'key': entry.key,
          'trust': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Map<RatchetMapKey, bool>> loadTrustEnablementList() async {
    final entries = await _db.query(omemoTrustEnableListTable);

    final mapEntries = entries.map<MapEntry<RatchetMapKey, bool>>((entry) {
      return MapEntry(
        RatchetMapKey.fromJsonKey(entry['key']! as String),
        intToBool(entry['enabled']! as int),
      );
    });

    return Map.fromEntries(mapEntries);
  }

  Future<void> saveTrustEnablementList(Map<String, bool> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustEnableListTable);
    for (final entry in list.entries) {
      batch.insert(
        omemoTrustEnableListTable,
        {
          'key': entry.key,
          'enabled': boolToInt(entry.value),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Map<String, List<int>>> loadTrustDeviceList() async {
    final entries = await _db.query(omemoTrustDeviceListTable);

    final map = <String, List<int>>{};
    for (final entry in entries) {
      final key = entry['jid']! as String;
      final device = entry['device']! as int;

      if (map.containsKey(key)) {
        map[key]!.add(device);
      } else {
        map[key] = [device];
      }
    }

    return map;
  }

  Future<void> saveTrustDeviceList(Map<String, List<int>> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustDeviceListTable);
    for (final entry in list.entries) {
      for (final device in entry.value) {
        batch.insert(
          omemoTrustDeviceListTable,
          {
            'jid': entry.key,
            'device': device,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit();
  }

  Future<void> saveOmemoDevice(Device device) async {
    await _db.insert(
      omemoDeviceTable,
      {
        'jid': device.jid,
        'id': device.id,
        'data': jsonEncode(await device.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Device?> loadOmemoDevice(String jid) async {
    final data = await _db.query(
      omemoDeviceTable,
      where: 'jid = ?',
      whereArgs: [jid],
      limit: 1,
    );
    if (data.isEmpty) return null;

    final deviceJson = jsonDecode(data.first['data']! as String) as Map<String, dynamic>;
    // NOTE: We need to do this because Dart otherwise complains about not being able
    //       to cast dynamic to List<int>.
    final opks = List<Map<String, dynamic>>.empty(growable: true);
    final opksIter = deviceJson['opks']! as List<dynamic>;
    for (final _opk in opksIter) {
      final opk = _opk as Map<String, dynamic>;
      opks.add(<String, dynamic>{
        'id': opk['id']! as int,
        'public': opk['public']! as String,
        'private': opk['private']! as String,
      });
    }
    deviceJson['opks'] = opks;
    return Device.fromJson(deviceJson);
  }

  Future<Map<String, List<int>>> loadOmemoDeviceList() async {
    final list = await _db.query(omemoDeviceListTable);
    final map = <String, List<int>>{};
    for (final entry in list) {
      final key = entry['jid']! as String;
      final id = entry['id']! as int;

      if (map.containsKey(key)) {
        map[key]!.add(id);
      } else {
        map[key] = [id];
      }
    }

    return map;
  }

  Future<void> saveOmemoDeviceList(Map<String, List<int>> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoDeviceListTable);
    for (final entry in list.entries) {
      for (final id in entry.value) {
        batch.insert(
          omemoDeviceListTable,
          {
            'jid': entry.key,
            'id': id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit();
  }

  Future<void> emptyOmemoSessionTables() async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch
      ..delete(omemoRatchetsTable)
      ..delete(omemoTrustCacheTable)
      ..delete(omemoTrustEnableListTable);

    await batch.commit();
  }
}
