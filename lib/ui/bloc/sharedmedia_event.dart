part of "sharedmedia_bloc.dart";

abstract class SharedMediaEvent {}

class SetSharedMedia extends SharedMediaEvent {
  final List<SharedMedium> sharedMedia;
  final String title;
  final String jid;

  SetSharedMedia(this.title, this.jid, this.sharedMedia);
}

class UpdatedSharedMedia extends SharedMediaEvent {
  final List<SharedMedium> sharedMedia;
  final String jid;

  UpdatedSharedMedia(this.jid, this.sharedMedia);
}
