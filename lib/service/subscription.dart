import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:synchronized/synchronized.dart';

class SubscriptionRequestService {
  List<String>? _subscriptionRequests;

  final Lock _lock = Lock();

  DatabaseService get _db => GetIt.I.get<DatabaseService>();

  /// Only load data from the database into
  /// [SubscriptionRequestService._subscriptionRequests] when the cache has not yet
  /// been loaded.
  Future<void> _loadSubscriptionRequestsIfNeeded() async {
    await _lock.synchronized(() async {
      _subscriptionRequests ??= List<String>.from(
        await _db.getSubscriptionRequests(),
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

        await _db.addSubscriptionRequest(jid);
      }
    });
  }

  Future<void> removeSubscriptionRequest(String jid) async {
    await _loadSubscriptionRequestsIfNeeded();

    await _lock.synchronized(() async {
      if (_subscriptionRequests!.contains(jid)) {
        _subscriptionRequests!.remove(jid);
        await _db.removeSubscriptionRequest(jid);
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
    _presence.sendSubscriptionRequestApproval(jid);
    await removeSubscriptionRequest(jid);
  }

  /// Reject a subscription request from [jid].
  Future<void> rejectSubscriptionRequest(String jid) async {
    _presence.sendSubscriptionRequestRejection(jid);
    await removeSubscriptionRequest(jid);
  }

  /// Send a subscription request to [jid].
  void sendSubscriptionRequest(String jid) {
    _presence.sendSubscriptionRequest(jid);
  }

  /// Remove a presence subscription with [jid].
  void sendUnsubscriptionRequest(String jid) {
    _presence.sendUnsubscriptionRequest(jid);
  }
}
