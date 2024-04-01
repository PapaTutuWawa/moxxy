import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';

part 'profile.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  factory ProfileState({
    @Default(false) bool isSelfProfile,
    @Default(null) Conversation? conversation,
    @Default('') String jid,
    @Default('') String avatarUrl,
    @Default('') String displayName,
  }) = _ProfileState;
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileState());

  void requestProfile(
    bool isSelfProfile, {
    Conversation? conversation,
    String? jid,
    String? avatarUrl,
    String? displayName,
  }) {
    if (isSelfProfile) {
      emit(
        state.copyWith(
          jid: jid!,
          avatarUrl: avatarUrl!,
          displayName: displayName!,
        ),
      );
    } else {
      emit(
        state.copyWith(
          conversation: conversation,
        ),
      );
    }

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            NavigationDestination(
              profileRoute,
              arguments: ProfileArguments(
                isSelfProfile,
                jid ?? conversation!.jid,
                conversation?.type ?? ConversationType.chat,
              ),
            ),
          ),
        );
  }

  Future<void> updateConversation(
    Conversation newConversation,
  ) async {
    if (state.conversation == null ||
        state.conversation!.jid != newConversation.jid) return;

    emit(state.copyWith(conversation: newConversation));
  }

  Future<void> setAvatar(
    String path,
    String hash,
    bool userTriggered,
  ) async {
    emit(
      state.copyWith(
        avatarUrl: path,
      ),
    );

    GetIt.I.get<AccountCubit>().changeAvatar(path, hash);

    if (userTriggered) {
      await getForegroundService().send(
        SetAvatarCommand(
          path: path,
          hash: hash,
        ),
        awaitable: false,
      );
    }
  }

  Future<void> setSubscriptionState(
    String jid,
    bool shareStatus,
  ) async {
    await getForegroundService().send(
      SetShareOnlineStatusCommand(jid: jid, share: shareStatus),
      awaitable: false,
    );
  }

  Future<void> setMuteState(
    String jid,
    bool muted,
  ) async {
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          muted: muted,
        ),
      ),
    );
    await getForegroundService().send(
      SetConversationMuteStatusCommand(jid: jid, muted: muted),
      awaitable: false,
    );
  }
}
