import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/roster.dart';

class MoxxyRosterStateManager extends BaseRosterStateManager {
  @override
  Future<RosterCacheLoadResult> loadRosterCache() async {
    final rs = GetIt.I.get<RosterService>();
    return RosterCacheLoadResult(
      (await GetIt.I.get<XmppStateService>().getXmppState()).lastRosterVersion,
      (await rs.getRoster()).map((item) => XmppRosterItem(
        jid: item.jid,
        name: item.title,
        subscription: item.subscription,
        ask: item.ask.isEmpty ? null : item.ask,
        groups: item.groups,
      ),).toList(),
    );
  }

  @override
  Future<void> commitRoster(String? version, List<String> removed, List<XmppRosterItem> modified, List<XmppRosterItem> added) async {
    final rs = GetIt.I.get<RosterService>();
    final xss = GetIt.I.get<XmppStateService>();
    await xss.modifyXmppState((state) => state.copyWith(
      lastRosterVersion: version,
    ),);

    // Remove stale items
    for (final jid in removed) {
      await rs.removeRosterItemByJid(jid);
    }
    
    // Create new roster items
    final rosterAdded = List<RosterItem>.empty(growable: true);
    for (final item in added) {
      rosterAdded.add(
        await rs.addRosterItemFromData(
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
        ),
      );

      // TODO(PapaTutuWawa): Fetch the avatar
    }

    // Update modified items
    final rosterModified = List<RosterItem>.empty(growable: true);
    for (final item in modified) {
      final ritem = await rs.getRosterItemByJid(item.jid);
      if (ritem == null) {
        //_log.warning('Could not find roster item with JID $jid during update');
        continue;
      }

      rosterModified.add(
        await rs.updateRosterItem(
          ritem.id,
          title: item.name,
          subscription: item.subscription,
          ask: item.ask,
          groups: item.groups,
        ),
      );
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
