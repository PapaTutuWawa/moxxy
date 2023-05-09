import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:moxxyv2/shared/warning_types.dart';

part 'message.freezed.dart';
part 'message.g.dart';

const pseudoMessageTypeNewDevice = 1;

Map<String, dynamic> _optionalJsonDecodeWithFallback(String? data) {
  if (data == null) return <String, dynamic>{};

  return (jsonDecode(data) as Map<dynamic, dynamic>).cast<String, dynamic>();
}

String? _optionalJsonEncodeWithFallback(Map<String, dynamic>? data) {
  if (data == null) return null;
  if (data.isEmpty) return null;

  return jsonEncode(data);
}

@freezed
class Message with _$Message {
  factory Message(
    String sender,
    String body,
    int timestamp,
    String sid,
    // The database-internal identifier of the message
    int id,
    String conversationJid,
    bool isFileUploadNotification,
    bool encrypted,
    // True if the message contains a <no-store> Message Processing Hint. False if not
    bool containsNoStore, {
    int? errorType,
    int? warningType,
    FileMetadata? fileMetadata,
    @Default(false) bool isDownloading,
    @Default(false) bool isUploading,
    @Default(false) bool received,
    @Default(false) bool displayed,
    @Default(false) bool acked,
    @Default(false) bool isRetracted,
    @Default(false) bool isEdited,
    String? originId,
    Message? quotes,
    @Default([]) List<Reaction> reactions,
    String? stickerPackId,
    int? pseudoMessageType,
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
      'reactions': <Map<String, dynamic>>[],
      'pseudoMessageData':
          _optionalJsonDecodeWithFallback(json['pseudoMessageData'] as String?)
    }).copyWith(
      quotes: quotes,
      reactions: (jsonDecode(json['reactions']! as String) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map<Reaction>(Reaction.fromJson)
          .toList(),
      fileMetadata: fileMetadata,
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('id')
      ..remove('quotes')
      ..remove('reactions')
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
      'reactions': jsonEncode(
        reactions.map((r) => r.toJson()).toList(),
      ),
      'pseudoMessageData': _optionalJsonEncodeWithFallback(pseudoMessageData),
    };
  }

  /// Returns true if the message is an error. If not, then returns false.
  bool get hasError => errorType != null && errorType != noError;

  /// Returns true if the message is a warning. If not, then returns false.
  bool get hasWarning => warningType != null && warningType != noWarning;

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
  bool get errorMenuVisible {
    return hasError &&
        (errorType! < messageNotEncryptedForDevice ||
            errorType! > messageInvalidAffixElements);
  }

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

  /// Returns true if the message is a sticker
  bool get isSticker =>
      isMedia &&
      stickerPackId != null &&
      !isPseudoMessage;

  /// True if the message is a media message
  bool get isMedia => fileMetadata != null;
}
