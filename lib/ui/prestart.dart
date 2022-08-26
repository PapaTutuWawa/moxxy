import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

/// Handler for when we received a [PreStartDoneEvent].
Future<void> preStartDone(PreStartDoneEvent result, { dynamic extra }) async {
  GetIt.I.get<Logger>().finest('Waiting for UI setup future to complete...');
  await GetIt.I.get<Completer<void>>().future;
  GetIt.I.get<Logger>().finest('Done');

  GetIt.I.get<PreferencesBloc>().add(
    PreferencesChangedEvent(result.preferences),
  );

  if (result.state == preStartLoggedInState) {
    GetIt.I.get<ConversationsBloc>().add(
      ConversationsInitEvent(
        result.displayName!,
        result.jid!,
        result.conversations!,
        avatarUrl: result.avatarUrl,
      ),
    );
    GetIt.I.get<NewConversationBloc>().add(
      NewConversationInitEvent(
        result.roster!,
      ),
    );
    GetIt.I.get<ConversationBloc>().add(OwnJidReceivedEvent(result.jid!));

    GetIt.I.get<Logger>().finest('Navigating to conversations');
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(conversationsRoute),
        (_) => false,
      ),
    );

    GetIt.I.get<ShareSelectionBloc>().add(
      ShareSelectionInitEvent(
        result.conversations!,
        result.roster!,
      ),
    );
  } else if (result.state == preStartNotLoggedInState) {
    GetIt.I.get<Logger>().finest('Navigating to intro');
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(introRoute),
        (_) => false,
      ),
    );
  }
}
