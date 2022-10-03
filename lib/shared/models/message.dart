import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/error_types.dart';
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
      String? originId,
      Message? quotes,
      String? filename,
      Map<String, String>? plaintextHashes,
      Map<String, String>? ciphertextHashes,
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
    }).copyWith(quotes: quotes);
  }
  
  Map<String, dynamic> toDatabaseJson(int? quoteId) {
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
      'quote_id': quoteId,
      'plaintextHashes': _optionalJsonEncode(plaintextHashes),
      'ciphertextHashes': _optionalJsonEncode(ciphertextHashes),
      'isDownloading': boolToInt(isDownloading),
      'isUploading': boolToInt(isUploading),
    };
  }

  /// Returns true if the message is an error. If not, then returns false.
  bool isError() {
    return errorType != null && errorType != noError;
  }

  /// Returns true if the message is a warning. If not, then returns false.
  bool isWarning() {
    return warningType != null && warningType != noWarning;
  }
}
