part of 'sendfiles_bloc.dart';

enum SendFilesType {
  media,
  generic,
}

abstract class SendFilesEvent {}

class SendFilesPageRequestedEvent extends SendFilesEvent {
  SendFilesPageRequestedEvent(
    this.recipients,
    this.type, {
    this.paths,
    this.hasRecipientData = true,
    this.popEntireStack = false,
  });
  final List<SendFilesRecipient> recipients;
  final SendFilesType type;
  final List<String>? paths;
  final bool hasRecipientData;
  final bool popEntireStack;
}

class IndexSetEvent extends SendFilesEvent {
  IndexSetEvent(this.index);
  final int index;
}

class AddFilesRequestedEvent extends SendFilesEvent {}

class FileSendingRequestedEvent extends SendFilesEvent {
  FileSendingRequestedEvent();
}

class ItemRemovedEvent extends SendFilesEvent {
  ItemRemovedEvent(this.index);
  final int index;
}

/// Triggered by the UI when the temporary files should be removed, i.e. all
/// files that are currently selected for sending. This is only useful on systems like
/// Android that only give us access using content URIs.
class RemovedCacheFilesEvent extends SendFilesEvent {}
