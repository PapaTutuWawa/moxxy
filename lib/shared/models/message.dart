import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/warning_types.dart';

part 'message.freezed.dart';
part 'message.g.dart';

Map<String, String>? _optionalJsonDecode(String? data) {
  if (data == null) return null;

  return jsonDecode(data) as Map<String, String>;
}

String? _optionalJsonEncode(Map<String, String>? data) {
  if (data == null) return null;

  return jsonEncode(data);
}

@freezed
class Message with _$Message {
  // NOTE: id is the database id of the message
  // NOTE: isMedia is for telling the UI that this message contains the URL for media but the path is not yet available
  // NOTE: srcUrl is the Url that a file has been or can be downloaded from
 
  factory Message(
    String sender,
    String body,
    int timestamp,
    String sid,
    int id,
    String conversationJid,
    bool isMedia,
    bool isFileUploadNotification,
    bool encrypted,
    {
      int? errorType,
      int? warningType,
      String? mediaUrl,
      @Default(false) bool isDownloading,
      @Default(false) bool isUploading,
      String? mediaType,
      String? thumbnailData,
      int? mediaWidth,
      int? mediaHeight,
      String? srcUrl,
      String? key,
      String? iv,
      String? encryptionScheme,
      @Default(false) bool received,
      @Default(false) bool displayed,
      @Default(false) bool acked,
      @Default(false) bool isRetracted,
      String? originId,
      Message? quotes,
      String? filename,
      Map<String, String>? plaintextHashes,
      Map<String, String>? ciphertextHashes,
      int? mediaSize,
    }
  ) = _Message;

  const Message._();

  /// JSON
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  factory Message.fromDatabaseJson(Map<String, dynamic> json, Message? quotes) {
    return Message.fromJson({
      ...json,
      'received': intToBool(json['received']! as int),
      'displayed': intToBool(json['displayed']! as int),
      'acked': intToBool(json['acked']! as int),
      'isMedia': intToBool(json['isMedia']! as int),
      'isFileUploadNotification': intToBool(json['isFileUploadNotification']! as int),
      'encrypted': intToBool(json['encrypted']! as int),
      'plaintextHashes': _optionalJsonDecode(json['plaintextHashes'] as String?),
      'ciphertextHashes': _optionalJsonDecode(json['ciphertextHashes'] as String?),
      'isDownloading': intToBool(json['isDownloading']! as int),
      'isUploading': intToBool(json['isUploading']! as int),
      'isRetracted': intToBool(json['isRetracted']! as int),
    }).copyWith(quotes: quotes);
  }
  
  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('id')
      ..remove('quotes');

    return {
      ...map,
      'isMedia': boolToInt(isMedia),
      'isFileUploadNotification': boolToInt(isFileUploadNotification),
      'received': boolToInt(received),
      'displayed': boolToInt(displayed),
      'acked': boolToInt(acked),
      'encrypted': boolToInt(encrypted),
      // NOTE: Message.quote_id is a foreign-key
      'quote_id': quotes?.id,
      'plaintextHashes': _optionalJsonEncode(plaintextHashes),
      'ciphertextHashes': _optionalJsonEncode(ciphertextHashes),
      'isDownloading': boolToInt(isDownloading),
      'isUploading': boolToInt(isUploading),
      'isRetracted': boolToInt(isRetracted),
    };
  }

  /// Returns true if the message is an error. If not, then returns false.
  bool get hasError => errorType != null && errorType != noError;

  /// Returns true if the message is a warning. If not, then returns false.
  bool get hasWarning => warningType != null && warningType != noWarning;

  /// Returns a representative emoji for a message. Its primary purpose is
  /// to provide a universal fallback for quoted media messages.
  String get messageEmoji {
    return mimeTypeToEmoji(mediaType, addTypeName: false);
  }

  /// Returns true if the message can be quoted. False if not.
  bool get isQuotable => !hasError && !isRetracted && !isFileUploadNotification && !isUploading && !isDownloading;

  /// Returns true if the message can be retracted. False if not.
  /// [sentBySelf] asks whether or not the message was sent by us (the current Jid).
  bool canRetract(bool sentBySelf) {
    return originId != null && sentBySelf && !isFileUploadNotification && !isUploading && !isDownloading;
  }

  /// Returns true if the message can be edited. False if not.
  /// [sentBySelf] asks whether or not the message was sent by us (the current Jid).
  bool canEdit(bool sentBySelf) {
    return sentBySelf && !isMedia && !isFileUploadNotification && !isUploading && !isDownloading;
  }

  /// Returns true if the message can open the selection menu by longpressing. False if
  /// not.
  bool get isLongpressable => !isRetracted;

  /// Returns true if the menu item to show the error should be shown in the
  /// longpress menu.
  bool get errorMenuVisible {
    return hasError && (
      errorType! < messageNotEncryptedForDevice ||
      errorType! > messageInvalidAffixElements
    );
  }

  /// Returns true if the message contains media that can be thumbnailed, i.e. videos or
  /// images.
  bool get isThumbnailable => isMedia && mediaType != null && (
    mediaType!.startsWith('image/') ||
    mediaType!.startsWith('video/')
  );

  /// Returns true if the message can be copied to the clipboard.
  bool get isCopyable => !isMedia && body.isNotEmpty;
}
