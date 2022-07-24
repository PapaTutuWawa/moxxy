part of 'sendfiles_bloc.dart';

abstract class SendFilesEvent {}

class SendFilesPageRequestedEvent extends SendFilesEvent {

  SendFilesPageRequestedEvent(this.jid);
  final String jid;
}

class IndexSetEvent extends SendFilesEvent {

  IndexSetEvent(this.index);
  final int index;
}

class AddFilesRequestedEvent extends SendFilesEvent {}

class FileSendingRequestedEvent extends SendFilesEvent {}
