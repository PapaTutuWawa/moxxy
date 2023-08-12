import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/warning_types.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum PseudoMessageType {
  /// Indicates that a new device was created in the chat.
  newDevice(1),

  /// Indicates that an existing device has been replaced.
  changedDevice(2);

  const PseudoMessageType(this.value);

  /// The identifier for the type of pseudo message.
  final int value;

  static PseudoMessageType? fromInt(int value) {
    switch (value) {
      case 1:
        return PseudoMessageType.newDevice;
      case 2:
        return PseudoMessageType.changedDevice;
    }

    return null;
  }
}

/// A converter for converting between [PseudoMessageType] and [int].
class PseudoMessageTypeConverter extends JsonConverter<PseudoMessageType, int> {
  const PseudoMessageTypeConverter();

  @override
  PseudoMessageType fromJson(int json) {
    return PseudoMessageType.fromInt(json)!;
  }

  @override
  int toJson(PseudoMessageType object) {
    return object.value;
  }
}

@freezed
class Message with _$Message {
  factory Message(
    // The message id (Moxxy-generated UUID).
    String id,

    /// The JID of the account that sent or received the message.
    String accountJid,

    /// The full JID of the sender
    String sender,

    /// The content of the <body /> tag
    String body,

    /// The timestamp the message was received
    int timestamp,

    /// The "id" attribute of the message stanza.
    String sid,

    /// The JID of the conversation this message was received/sent in.
    String conversationJid,

    /// Flag indicating whether the message is a file upload notification.
    bool isFileUploadNotification,

    /// Flag indicating whether the message was sent/received encrypted.
    bool encrypted,

    /// True if the message contains a <no-store> Message Processing Hint. False if not
    bool containsNoStore, {
    /// A message's associated error, if applicable (e.g. crypto error, file upload failure, ...).
    @MessageErrorTypeConverter() MessageErrorType? errorType,

    /// A message's associated warning, if applicable.
    @MessageWarningTypeConverter() MessageWarningType? warningType,

    /// If a file is attached, this is a reference to the file metadata.
    FileMetadata? fileMetadata,

    /// Flag indicating whether the message's file is currently being downloaded.
    @Default(false) bool isDownloading,

    /// Flag indicating whether the message's file is currently being uploaded.
    @Default(false) bool isUploading,

    /// Flag indicating whether the message was marked as received.
    @Default(false) bool received,

    /// If the message was sent by us, this means that the recipient has displayed the message.
    /// If we received the message, then this means that we sent a read marker for that message.
    @Default(false) bool displayed,

    /// Specified whether the message has been acked using stream management, i.e. it was successfully sent to
    /// the server.
    @Default(false) bool acked,

    /// Indicates whether the message has been retracted.
    @Default(false) bool isRetracted,

    /// Indicates whether the message has been edited.
    @Default(false) bool isEdited,

    /// An optional origin id attached to the message
    String? originId,

    /// The message this message quotes using XEP-0461
    Message? quotes,

    /// A short summary of reactions, if available
    @Default([]) List<String> reactionsPreview,

    /// The ID of the sticker pack the sticker belongs to, if the message
    /// contains a sticker.
    String? stickerPackId,

    /// If the message is not a real message, then this field indicates
    /// the type of "pseudo message" we should display.
    @PseudoMessageTypeConverter() PseudoMessageType? pseudoMessageType,

    /// The associated data for "pseudo messages".
    Map<String, dynamic>? pseudoMessageData,
  }) = _Message;

  const Message._();

  /// JSON
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  factory Message.fromDatabaseJson(
    Map<String, dynamic> json,
    Message? quotes,
    FileMetadata? fileMetadata,
    List<String> reactionsPreview,
  ) {
    return Message.fromJson({
      ...json,
      'received': intToBool(json['received']! as int),
      'displayed': intToBool(json['displayed']! as int),
      'acked': intToBool(json['acked']! as int),
      'isFileUploadNotification':
          intToBool(json['isFileUploadNotification']! as int),
      'encrypted': intToBool(json['encrypted']! as int),
      'isDownloading': intToBool(json['isDownloading']! as int),
      'isUploading': intToBool(json['isUploading']! as int),
      'isRetracted': intToBool(json['isRetracted']! as int),
      'isEdited': intToBool(json['isEdited']! as int),
      'containsNoStore': intToBool(json['containsNoStore']! as int),
      'reactionsPreview': reactionsPreview,
      'pseudoMessageData': (json['pseudoMessageData'] as String?)?.fromJson(),
    }).copyWith(
      quotes: quotes,
      fileMetadata: fileMetadata,
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('id')
      ..remove('quotes')
      ..remove('reactionsPreview')
      ..remove('fileMetadata')
      ..remove('pseudoMessageData');

    return {
      ...map,
      'isFileUploadNotification': boolToInt(isFileUploadNotification),
      'received': boolToInt(received),
      'displayed': boolToInt(displayed),
      'acked': boolToInt(acked),
      'encrypted': boolToInt(encrypted),
      'file_metadata_id': fileMetadata?.id,
      // NOTE: Message.quote_id is a foreign-key
      'quote_id': quotes?.id,
      'isDownloading': boolToInt(isDownloading),
      'isUploading': boolToInt(isUploading),
      'isRetracted': boolToInt(isRetracted),
      'isEdited': boolToInt(isEdited),
      'containsNoStore': boolToInt(containsNoStore),
      'pseudoMessageData': pseudoMessageData?.toJson(),
    };
  }

  /// True if the [errorType] describes an error related to OMEMO.
  bool get isOmemoError => [
        MessageErrorType.notEncryptedForDevice,
        MessageErrorType.invalidHMAC,
        MessageErrorType.noDecryptionKey,
        MessageErrorType.invalidAffixElements,
        MessageErrorType.failedToEncrypt,
        MessageErrorType.failedToDecryptFile,
        MessageErrorType.omemoNotSupported,
        MessageErrorType.failedToEncryptFile,
      ].contains(errorType);

  /// Returns true if the message is an error. If not, then returns false.
  bool get hasError =>
      errorType != null && errorType != MessageErrorType.noError;

  /// Returns true if the message is a warning. If not, then returns false.
  bool get hasWarning =>
      warningType != null && warningType != MessageWarningType.noWarning;

  /// Returns a representative emoji for a message. Its primary purpose is
  /// to provide a universal fallback for quoted media messages.
  String get messageEmoji {
    return mimeTypeToEmoji(fileMetadata?.mimeType, addTypeName: false);
  }

  /// True if the message is a pseudo message.
  bool get isPseudoMessage =>
      pseudoMessageType != null && pseudoMessageData != null;

  /// Returns true if the message can be quoted. False if not.
  bool get isQuotable =>
      !hasError &&
      !isRetracted &&
      !isFileUploadNotification &&
      !isUploading &&
      !isDownloading &&
      !isPseudoMessage;

  /// Returns true if the message can be retracted. False if not.
  /// [sentBySelf] asks whether or not the message was sent by us (the current Jid).
  bool canRetract(bool sentBySelf) {
    return !hasError &&
        originId != null &&
        sentBySelf &&
        !isFileUploadNotification &&
        !isUploading &&
        !isDownloading &&
        !isPseudoMessage;
  }

  /// Returns true if we can send a reaction for this message.
  bool get isReactable =>
      !hasError &&
      !isRetracted &&
      !isFileUploadNotification &&
      !isUploading &&
      !isDownloading &&
      !isPseudoMessage;

  /// Returns true if the message can be edited. False if not.
  /// [sentBySelf] asks whether or not the message was sent by us (the current Jid).
  bool canEdit(bool sentBySelf) {
    return !hasError &&
        sentBySelf &&
        !isMedia &&
        !isFileUploadNotification &&
        !isUploading &&
        !isDownloading &&
        !isPseudoMessage;
  }

  /// Returns true if the message can open the selection menu by longpressing. False if
  /// not.
  bool get isLongpressable => !isRetracted && !isPseudoMessage;

  /// Returns true if the menu item to show the error should be shown in the
  /// longpress menu.
  bool get errorMenuVisible => hasError && !isOmemoError;

  /// Returns true if the message contains media that can be thumbnailed, i.e. videos or
  /// images.
  bool get isThumbnailable {
    if (isPseudoMessage || !isMedia || fileMetadata?.mimeType == null) {
      return false;
    }

    final mimeType = fileMetadata!.mimeType!;
    return mimeType.startsWith('image/') || mimeType.startsWith('video/');
  }

  /// Returns true if the message can be copied to the clipboard.
  bool get isCopyable => !isMedia && body.isNotEmpty && !isPseudoMessage;

  /// Returns true if the message is a sticker.
  bool get isSticker => isMedia && stickerPackId != null && !isPseudoMessage;

  /// True if the message is a media message.
  bool get isMedia => fileMetadata != null;

  /// The JID of the sender in moxxmpp's format.
  JID get senderJid => JID.fromString(sender);
}
