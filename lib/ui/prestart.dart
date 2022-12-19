import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:share_handler/share_handler.dart';

/// Handler for when we received a [PreStartDoneEvent].
Future<void> preStartDone(PreStartDoneEvent result, { dynamic extra }) async {
  GetIt.I.get<PreferencesBloc>().add(
    PreferencesChangedEvent(result.preferences),
  );

  WidgetsFlutterBinding.ensureInitialized();
  if (result.preferences.languageLocaleCode == 'default') {
    LocaleSettings.useDeviceLocale();
  } else {
    LocaleSettings.setLocaleRaw(result.preferences.languageLocaleCode);
  }
  
  if (result.state == preStartLoggedInState) {
    // Set up the data service
    GetIt.I.get<UIDataService>().processPreStartDoneEvent(result);

    // Set up the BLoCs
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
    GetIt.I.get<StickersBloc>().add(
      StickersSetEvent(
        result.stickers!,
      ),
    );

    GetIt.I.get<Logger>().finest('Navigating to conversations');

    // Only go to the Conversations page when we did not start due to a sharing intent
    final handler = ShareHandlerPlatform.instance;
    if (await handler.getInitialSharedMedia() == null) {
      GetIt.I.get<NavigationBloc>().add(
        PushedNamedAndRemoveUntilEvent(
          const NavigationDestination(conversationsRoute),
          (_) => false,
        ),
      );
    }

    GetIt.I.get<ShareSelectionBloc>().add(
      ShareSelectionInitEvent(
        result.conversations!,
        result.roster!,
      ),
    );
  } else if (result.state == preStartNotLoggedInState) {
    GetIt.I.get<UIDataService>().isLoggedIn = false;
    GetIt.I.get<Logger>().finest('Navigating to intro');
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(introRoute),
        (_) => false,
      ),
    );
  }
}
