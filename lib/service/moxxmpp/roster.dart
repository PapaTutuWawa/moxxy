import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/roster.dart';

/// Update the "showAddToRoster" state of the conversation with jid [jid] to
/// [showAddToRoster], if the conversation exists.
Future<void> updateConversation(String jid, bool showAddToRoster) async {
  final cs = GetIt.I.get<ConversationService>();
  final newConversation = await cs.createOrUpdateConversation(
    jid,
    update: (conversation) async {
      final c = conversation.copyWith(
        showAddToRoster: showAddToRoster,
      );
      cs.setConversation(c);
      return c;
    },
  );
  if (newConversation != null) {
    sendEvent(ConversationUpdatedEvent(conversation: newConversation));
  }
}

class MoxxyRosterStateManager extends BaseRosterStateManager {
  @override
  Future<RosterCacheLoadResult> loadRosterCache() async {
    final rs = GetIt.I.get<RosterService>();
    return RosterCacheLoadResult(
      (await GetIt.I.get<XmppStateService>().getXmppState()).lastRosterVersion,
      (await rs.getRoster())
          .map(
            (item) => XmppRosterItem(
              jid: item.jid,
              name: item.title,
              subscription: item.subscription,
              ask: item.ask.isEmpty ? null : item.ask,
              groups: item.groups,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> commitRoster(
    String? version,
    List<String> removed,
    List<XmppRosterItem> modified,
    List<XmppRosterItem> added,
  ) async {
    final rs = GetIt.I.get<RosterService>();
    final xss = GetIt.I.get<XmppStateService>();
    await xss.modifyXmppState(
      (state) => state.copyWith(
        lastRosterVersion: version,
      ),
    );

    // Remove stale items
    for (final jid in removed) {
      await rs.removeRosterItemByJid(jid);
      await updateConversation(jid, true);
    }

    // Create new roster items
    final rosterAdded = List<RosterItem>.empty(growable: true);
    for (final item in added) {
      final exists = await rs.getRosterItemByJid(item.jid) != null;
      // Skip adding items twice
      if (exists) continue;

      final newRosterItem = await rs.addRosterItemFromData(
        '',
        '',
        item.jid,
        item.name ?? item.jid.split('@').first,
        item.subscription,
        item.ask ?? '',
        false,
        null,
        null,
        null,
        groups: item.groups,
      );
      rosterAdded.add(newRosterItem);

      // Update the cached conversation item
      await updateConversation(item.jid, newRosterItem.showAddToRosterButton);
    }

    // Update modified items
    final rosterModified = List<RosterItem>.empty(growable: true);
    for (final item in modified) {
      final ritem = await rs.getRosterItemByJid(item.jid);
      if (ritem == null) {
        //_log.warning('Could not find roster item with JID $jid during update');
        continue;
      }

      final newRosterItem = await rs.updateRosterItem(
        ritem.id,
        title: item.name,
        subscription: item.subscription,
        ask: item.ask,
        groups: item.groups,
      );
      rosterModified.add(newRosterItem);

      // Update the cached conversation item
      await updateConversation(item.jid, newRosterItem.showAddToRosterButton);
    }

    // Tell the UI
    // TODO(Unknown): This may not be the cleanest place to put it
    sendEvent(
      RosterDiffEvent(
        added: rosterAdded,
        modified: rosterModified,
        removed: removed,
      ),
    );
  }
}
