part of 'sendfiles_bloc.dart';

enum SendFilesType {
  image,
  generic,
}

abstract class SendFilesEvent {}

class SendFilesPageRequestedEvent extends SendFilesEvent {

  SendFilesPageRequestedEvent(this.jid, this.type);
  final String jid;
  final SendFilesType type;
}

class IndexSetEvent extends SendFilesEvent {

  IndexSetEvent(this.index);
  final int index;
}

class AddFilesRequestedEvent extends SendFilesEvent {}

class FileSendingRequestedEvent extends SendFilesEvent {}

class ItemRemovedEvent extends SendFilesEvent {

  ItemRemovedEvent(this.index);
  final int index;
}
