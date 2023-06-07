import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:synchronized/synchronized.dart';

// TODO: Remove
class SubscriptionRequestService {
  List<String>? _subscriptionRequests;

  final Lock _lock = Lock();

  /// Only load data from the database into
  /// [SubscriptionRequestService._subscriptionRequests] when the cache has not yet
  /// been loaded.
  Future<void> _loadSubscriptionRequestsIfNeeded() async {
    await _lock.synchronized(() async {
      _subscriptionRequests ??= List<String>.from(
        (await GetIt.I
                .get<DatabaseService>()
                .database
                .query(subscriptionsTable))
            .map((m) => m['jid']! as String)
            .toList(),
      );
    });
  }

  Future<List<String>> getSubscriptionRequests() async {
    await _loadSubscriptionRequestsIfNeeded();
    return _subscriptionRequests!;
  }

  Future<void> addSubscriptionRequest(String jid) async {
    await _loadSubscriptionRequestsIfNeeded();

    await _lock.synchronized(() async {
      if (!_subscriptionRequests!.contains(jid)) {
        _subscriptionRequests!.add(jid);

        await GetIt.I.get<DatabaseService>().database.insert(
              subscriptionsTable,
              {
                'jid': jid,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
      }
    });
  }

  Future<void> removeSubscriptionRequest(String jid) async {
    await _loadSubscriptionRequestsIfNeeded();

    await _lock.synchronized(() async {
      if (_subscriptionRequests!.contains(jid)) {
        _subscriptionRequests!.remove(jid);
        await GetIt.I.get<DatabaseService>().database.delete(
          subscriptionsTable,
          where: 'jid = ?',
          whereArgs: [jid],
        );
      }
    });
  }

  Future<bool> hasPendingSubscriptionRequest(String jid) async {
    return (await getSubscriptionRequests()).contains(jid);
  }

  PresenceManager get _presence =>
      GetIt.I.get<XmppConnection>().getPresenceManager()!;

  /// Accept a subscription request from [jid].
  Future<void> acceptSubscriptionRequest(String jid) async {
    //_presence.sendSubscriptionRequestApproval(jid, preApprove: true);
    await removeSubscriptionRequest(jid);
  }

  /// Reject a subscription request from [jid].
  Future<void> rejectSubscriptionRequest(String jid) async {
    _presence.sendSubscriptionRequestRejection(jid);
    await removeSubscriptionRequest(jid);
  }

  /// Send a subscription request to [jid].
  void sendSubscriptionRequest(String jid, {bool preApprove = true}) {
    _presence.sendSubscriptionRequest(jid, preApprove: preApprove);
  }

  /// Remove a presence subscription with [jid].
  void sendUnsubscriptionRequest(String jid) {
    _presence.sendUnsubscriptionRequest(jid);
  }
}
