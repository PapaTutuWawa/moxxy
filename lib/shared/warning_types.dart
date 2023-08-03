import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/i18n/strings.g.dart';

enum MessageWarningType {
  // TODO(Unknown): Maybe remove
  noWarning(0),

  /// The file was able to get decrypted but the integrity check failed.
  fileIntegrityCheckFailed(1),

  /// The chat is configured to be encrypted, but the file that was received
  /// was unencrypted.
  chatEncryptedButFilePlaintext(2);

  const MessageWarningType(this.value);

  static MessageWarningType? fromInt(int? value) {
    if (value == null) {
      return null;
    }

    if (value == MessageWarningType.noWarning.value) {
      return MessageWarningType.noWarning;
    } else if (value == MessageWarningType.fileIntegrityCheckFailed.value) {
      return MessageWarningType.fileIntegrityCheckFailed;
    } else if (value ==
        MessageWarningType.chatEncryptedButFilePlaintext.value) {
      return MessageWarningType.chatEncryptedButFilePlaintext;
    }

    throw Exception('Invalid MessageWarningType $value');
  }

  /// The id of the warning.
  final int value;

  String get translatableString {
    assert(
      this != MessageWarningType.noWarning,
      'The translatableString of MessageWarningType.noWarning makes no sense',
    );

    switch (this) {
      case fileIntegrityCheckFailed:
        return t.warnings.message.integrityCheckFailed;
      case chatEncryptedButFilePlaintext:
        // TODO: Move this to warnings
        return t.errors.message.fileNotEncrypted;
      case noWarning:
        return '';
    }
  }
}

/// A converter for converting between [MessageWarningType] and [int].
class MessageWarningTypeConverter
    implements JsonConverter<MessageWarningType, int> {
  const MessageWarningTypeConverter();

  @override
  MessageWarningType fromJson(int json) {
    return MessageWarningType.fromInt(json)!;
  }

  @override
  int toJson(MessageWarningType data) => data.value;
}
