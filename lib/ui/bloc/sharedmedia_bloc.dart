import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/shared/models/media.dart';

part 'sharedmedia_bloc.freezed.dart';
part 'sharedmedia_event.dart';
part 'sharedmedia_state.dart';

class SharedMediaBloc extends Bloc<SharedMediaEvent, SharedMediaState> {
  SharedMediaBloc() : super(SharedMediaState()) {
    on<SetSharedMedia>(_onSetSharedMedia);
    on<UpdatedSharedMedia>(_onUpdatedSharedMedia);
    on<JidRemovedEvent>(_onJidRemoved);
  }

  Future<void> _onJidRemoved(JidRemovedEvent event, Emitter<SharedMediaState> emit) async {
    emit(state.copyWith(jid: ''));
  }
  
  Future<void> _onUpdatedSharedMedia(UpdatedSharedMedia event, Emitter<SharedMediaState> emit) async {
    if (state.jid != event.jid) return;

    emit(
      state.copyWith(
        sharedMedia: event.sharedMedia,
      ),
    );
  }
  
  Future<void> _onSetSharedMedia(SetSharedMedia event, Emitter<SharedMediaState> emit) async {
    emit(
      state.copyWith(
        sharedMedia: event.sharedMedia,
        title: event.title,
        jid: event.jid,
      ),
    );
  }
}
