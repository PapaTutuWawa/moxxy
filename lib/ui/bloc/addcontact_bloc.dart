import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';

part 'addcontact_bloc.freezed.dart';
part 'addcontact_event.dart';
part 'addcontact_state.dart';

class AddContactBloc extends Bloc<AddContactEvent, AddContactState> {
  AddContactBloc() : super(AddContactState()) {
    on<AddedContactEvent>(_onContactAdded);
    on<JidChangedEvent>(_onJidChanged);
  }

  Future<void> _onContactAdded(AddedContactEvent event, Emitter<AddContactState> emit) async {
    // TODO(Unknown): Remove once we can disable the custom buttom
    if (state.working) return;

    final validation = validateJidString(state.jid);
    if (validation != null) {
      emit(state.copyWith(jidError: validation));
      return;
    }

    emit(
      state.copyWith(
        working: true,
        jidError: null,
      ),
    );

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      AddContactCommand(
        jid: state.jid,
      ),
    ) as AddContactResultEvent;

    if (result.conversation != null) {
      if (result.added) {
        GetIt.I.get<ConversationsBloc>().add(ConversationsAddedEvent(result.conversation!));
      } else {
        GetIt.I.get<ConversationsBloc>().add(ConversationsUpdatedEvent(result.conversation!));
      }
    }

    GetIt.I.get<ConversationBloc>().add(
      RequestedConversationEvent(
        result.conversation!.jid,
        result.conversation!.title,
        result.conversation!.avatarUrl,
        removeUntilConversations: true,
      ),
    );
  }

  Future<void> _onJidChanged(JidChangedEvent event, Emitter<AddContactState> emit) async {
    emit(state.copyWith(jid: event.jid));
  }
}
