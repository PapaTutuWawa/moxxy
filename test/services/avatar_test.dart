import 'dart:async';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/shared/models/xmpp_state.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Enable logging using logger.
void initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}',
    );
  });
}

class StubConversationService extends ConversationService {
  Conversation? conversation;

  @override
  Future<Conversation?> getConversationByJid(
    String jid,
    String accountJid,
  ) async =>
      conversation;

  @override
  Future<Conversation?> createOrUpdateConversation(
    String jid,
    String accountJid, {
    CreateConversationCallback? create,
    UpdateConversationCallback? update,
    PreRunConversationCallback? preRun,
  }) async {
    return conversation;
  }
}

class StubRosterService extends RosterService {
  @override
  Future<RosterItem?> getRosterItemByJid(String jid, String accountJid) async =>
      null;
}

class StubXmppStateService extends XmppStateService {
  @override
  Future<String?> getAccountJid() async => 'user@example';

  @override
  Future<XmppState> get state async => XmppState(
        avatarHash: '9f26dcd75b630308df29214880a4e26fe5ef3a43',
        avatarUrl: './cache/avatars/9f26dcd75b630308df29214880a4e26fe5ef3a43',
      );

  @override
  Future<void> modifyXmppState(
    XmppState Function(XmppState) func, {
    bool commit = true,
  }) async {}
}

class StubNotificationsService extends NotificationsService {
  @override
  Future<void> maybeSetAvatarFromState() async {}
}

class StubSocketWrapper extends BaseSocketWrapper {
  @override
  void close() {}

  @override
  Future<bool> connect(String domain, {String? host, int? port}) {
    throw UnimplementedError();
  }

  @override
  Stream<String> getDataStream() {
    return StreamController<String>.broadcast().stream;
  }

  @override
  Stream<XmppSocketEvent> getEventStream() {
    return StreamController<XmppSocketEvent>().stream;
  }

  @override
  bool isSecure() {
    throw UnimplementedError();
  }

  @override
  bool managesKeepalives() {
    throw UnimplementedError();
  }

  @override
  Future<bool> secure(String domain) {
    throw UnimplementedError();
  }

  @override
  bool whitespacePingAllowed() {
    throw UnimplementedError();
  }

  @override
  void write(String data) {}
}

const Map<String, String> _avatars = {
  '9f26dcd75b630308df29214880a4e26fe5ef3a43': 'deadbeef',
  'd6d556595ff55705010e44c9aab1079dbf5b4fb9': 'beef',
};

class StubUserAvatarManager extends UserAvatarManager {
  StubUserAvatarManager() : super();

  int getUserAvatarCalled = 0;

  String currentAvatarHash = '';

  String currentAvatarType = 'image/png';

  List<UserAvatarMetadata>? metadataList;

  @override
  Future<Result<AvatarError, List<UserAvatarMetadata>>> getLatestMetadata(
    JID jid,
  ) async {
    return Result<AvatarError, List<UserAvatarMetadata>>(
      metadataList ??
          [
            UserAvatarMetadata(
              currentAvatarHash,
              42,
              null,
              null,
              currentAvatarType,
              null,
            ),
          ],
    );
  }

  @override
  Future<Result<AvatarError, UserAvatarData>> getUserAvatarData(
    JID jid,
    String id,
  ) async {
    getUserAvatarCalled++;
    return Result<AvatarError, UserAvatarData>(
      UserAvatarData(
        _avatars[id]!,
        id,
      ),
    );
  }
}

class StubXmppConnection extends XmppConnection {
  StubXmppConnection()
      : super(
          TestingReconnectionPolicy(),
          AlwaysConnectedConnectivityManager(),
          ClientToServerNegotiator(),
          StubSocketWrapper(),
        );
}

class StubBackgroundService extends BackgroundService {
  @override
  Future<void> init(ServiceConfig config) async {}

  @override
  Future<void> send(BackgroundEvent event, {String? id}) async {}

  @override
  void setNotificationBody(String body) {}
}

class MockedAvatarService extends AvatarService {
  bool canRemove = true;

  @override
  Future<bool> canRemoveAvatar(String path, bool ignoreSelf) async => canRemove;
}

Future<void> main() async {
  initLogger();

  // Ensure we have no artifacts
  // TODO(Unknown): Find a better solution
  const cacheDir = './cache/avatars';
  if (Directory(cacheDir).existsSync()) {
    // ignore: avoid_print
    print('!!! Artifact directory $cacheDir exists.');
    exit(1);
  }

  final srv = MockedAvatarService()..initializeForTesting(cacheDir);
  final conn = StubXmppConnection();
  final stubUserAvatarManager = StubUserAvatarManager();
  await conn.registerManagers([stubUserAvatarManager]);
  GetIt.I.registerSingleton<XmppConnection>(conn);
  final scs = StubConversationService();
  GetIt.I.registerSingleton<ConversationService>(scs);
  GetIt.I.registerSingleton<RosterService>(StubRosterService());
  GetIt.I.registerSingleton<XmppStateService>(StubXmppStateService());
  GetIt.I.registerSingleton<NotificationsService>(StubNotificationsService());
  GetIt.I.registerSingleton<Logger>(Logger('root'));
  GetIt.I.registerSingleton<BackgroundService>(StubBackgroundService());

  setUp(() async {
    stubUserAvatarManager
      ..currentAvatarHash = ''
      ..currentAvatarType = 'image/png'
      ..metadataList = null
      ..getUserAvatarCalled = 0;
    scs.conversation = null;

    // Remove artifacts, if they exist
    if (Directory(cacheDir).existsSync()) {
      try {
        await Directory(cacheDir).delete(recursive: true);
      } catch (ex) {
        Logger('Teardown').info('Failed to remove $cacheDir: $ex');
        exit(1);
      }
    }
  });

  tearDown(() async {
    // Remove artifacts, if they exist
    if (Directory(cacheDir).existsSync()) {
      try {
        await Directory(cacheDir).delete(recursive: true);
      } catch (ex) {
        Logger('Teardown').info('Failed to remove $cacheDir: $ex');
        exit(1);
      }
    }
  });

  test('Test deduplicating', () async {
    stubUserAvatarManager.currentAvatarHash =
        '9f26dcd75b630308df29214880a4e26fe5ef3a43';
    final result1 =
        await srv.requestAvatar(JID.fromString('user@example.org'), null);
    expect(result1 != null, true);
    final result2 =
        await srv.requestAvatar(JID.fromString('other-user@example.org'), null);
    expect(result2, result1);
    expect(stubUserAvatarManager.getUserAvatarCalled, 1);
  });

  test('Test updating an avatar and removing the old one', () async {
    srv.canRemove = true;

    // Get avatar 1.
    stubUserAvatarManager.currentAvatarHash =
        '9f26dcd75b630308df29214880a4e26fe5ef3a43';
    await srv.requestAvatar(JID.fromString('user@example.org'), null);

    // Create a fake conversation
    scs.conversation = Conversation(
      '',
      '',
      null,
      p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'),
      '9f26dcd75b630308df29214880a4e26fe5ef3a43',
      'user@example.org',
      null,
      0,
      ConversationType.chat,
      -1,
      true,
      false,
      false,
      false,
      ChatState.gone,
    );

    // The user updates their avatar.
    stubUserAvatarManager.currentAvatarHash =
        'd6d556595ff55705010e44c9aab1079dbf5b4fb9';
    await srv.handleAvatarUpdate(
      UserAvatarUpdatedEvent(
        JID.fromString('user@example.org'),
        [
          const UserAvatarMetadata(
            'd6d556595ff55705010e44c9aab1079dbf5b4fb9',
            2,
            null,
            null,
            'image/png',
            null,
          ),
        ],
      ),
    );

    // The first avatar should not exist anymore.
    expect(
      File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      false,
    );
  });

  test('Test updating an avatar and not removing the old one', () async {
    srv.canRemove = false;

    // Get avatar 1.
    stubUserAvatarManager.currentAvatarHash =
        '9f26dcd75b630308df29214880a4e26fe5ef3a43';
    await srv.requestAvatar(JID.fromString('user@example.org'), null);

    // Create a fake conversation
    scs.conversation = Conversation(
      '',
      '',
      null,
      p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'),
      '9f26dcd75b630308df29214880a4e26fe5ef3a43',
      'user@example.org',
      null,
      0,
      ConversationType.chat,
      -1,
      true,
      false,
      false,
      false,
      ChatState.gone,
    );

    // The user updates their avatar.
    stubUserAvatarManager.currentAvatarHash =
        'd6d556595ff55705010e44c9aab1079dbf5b4fb9';
    await srv.handleAvatarUpdate(
      UserAvatarUpdatedEvent(
        JID.fromString('user@example.org'),
        [
          const UserAvatarMetadata(
            'd6d556595ff55705010e44c9aab1079dbf5b4fb9',
            2,
            null,
            null,
            'image/png',
            null,
          ),
        ],
      ),
    );

    // The first avatar should still exist.
    expect(
      File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      true,
    );
  });

  test('Test fetching a matching id avatar if the file does not exist',
      () async {
    // The avatar must not exist already.
    assert(
      !File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      'The avatar must not already exist',
    );

    // Get avatar 1.
    stubUserAvatarManager.currentAvatarHash =
        '9f26dcd75b630308df29214880a4e26fe5ef3a43';
    await srv.requestAvatar(
      JID.fromString('user@example.org'),
      '9f26dcd75b630308df29214880a4e26fe5ef3a43',
    );

    // The first avatar should now exist.
    expect(stubUserAvatarManager.getUserAvatarCalled, 1);
    expect(
      File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      true,
    );
  });

  test(
      'Test fetching a matching id avatar for ourselves if the file does not exist',
      () async {
    // The avatar must not exist already.
    assert(
      !File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      'The avatar must not already exist',
    );

    // Get avatar 1.
    stubUserAvatarManager.currentAvatarHash =
        '9f26dcd75b630308df29214880a4e26fe5ef3a43';
    await srv.requestOwnAvatar();

    // The first avatar should now exist.
    expect(stubUserAvatarManager.getUserAvatarCalled, 1);
    expect(
      File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      true,
    );
  });

  test('Test fetching avatars with no advertised PNG avatar', () async {
    // The avatar must not exist already.
    assert(
      !File(p.join(cacheDir, '9f26dcd75b630308df29214880a4e26fe5ef3a43'))
          .existsSync(),
      'The avatar must not already exist',
    );

    // Get the avatar.
    stubUserAvatarManager.metadataList = const [
      UserAvatarMetadata(
        '9f26dcd75b630308df29214880a4e26fe5ef3a43',
        42,
        null,
        null,
        'image/tiff',
        null,
      ),
      UserAvatarMetadata(
        'd6d556595ff55705010e44c9aab1079dbf5b4fb9',
        42,
        null,
        null,
        'image/jpeg',
        null,
      ),
    ];
    await srv.requestAvatar(JID.fromString('user@example.org'), null);

    // The avatar jpeg avatar should now exist.
    expect(stubUserAvatarManager.getUserAvatarCalled, 1);
    expect(
      File(p.join(cacheDir, 'd6d556595ff55705010e44c9aab1079dbf5b4fb9'))
          .existsSync(),
      true,
    );

    // Request the avatar again.
    await srv.requestAvatar(
      JID.fromString('user@example.org'),
      'd6d556595ff55705010e44c9aab1079dbf5b4fb9',
    );
    // If the sorting is stable, then getUserAvatar should only be called once.
    expect(stubUserAvatarManager.getUserAvatarCalled, 1);
  });
}
