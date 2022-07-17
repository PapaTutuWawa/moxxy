part of 'sharedmedia_bloc.dart';

abstract class SharedMediaEvent {}

class SetSharedMedia extends SharedMediaEvent {

  SetSharedMedia(this.title, this.jid, this.sharedMedia);
  final List<SharedMedium> sharedMedia;
  final String title;
  final String jid;
}

class UpdatedSharedMedia extends SharedMediaEvent {

  UpdatedSharedMedia(this.jid, this.sharedMedia);
  final List<SharedMedium> sharedMedia;
  final String jid;
}
