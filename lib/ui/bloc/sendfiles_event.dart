part of 'sendfiles_bloc.dart';

abstract class SendFilesEvent {}

class SendFilesPageRequestedEvent extends SendFilesEvent {

  SendFilesPageRequestedEvent(this.files);
  final List<String> files;
}

class IndexSetEvent extends SendFilesEvent {

  IndexSetEvent(this.index);
  final int index;
}

class AddFilesRequestedEvent extends SendFilesEvent {

  AddFilesRequestedEvent();
}
