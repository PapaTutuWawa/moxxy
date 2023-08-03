import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:omemo_dart/omemo_dart.dart';

enum ErrorType {
  unknown(-1),
  remoteServerNotFound(0),
  remoteServerTimeout(1);

  const ErrorType(this.value);

  factory ErrorType.fromValue(int value) {
    switch (value) {
      case 0:
        return ErrorType.remoteServerNotFound;
      case 1:
        return ErrorType.remoteServerTimeout;
      default:
        return ErrorType.unknown;
    }
  }

  /// The identifier value of this error type.
  final int value;
}

enum MessageErrorType {
  unspecified(-1),
  // TODO(Unknown): Maybe remove
  noError(0),

  /// The file upload failed.
  fileUploadFailed(1),

  /// The received message was not encrypted for this device.
  notEncryptedForDevice(2),

  /// The HMAC of the encrypted message is wrong.
  invalidHMAC(3),

  /// We have no key available to decrypt the message.
  noDecryptionKey(4),

  /// The sanity-checks on the included affix elements failed.
  invalidAffixElements(5),

  /// The encryption of the message somehow failed.
  failedToEncrypt(7),

  /// The decryption of the file failed.
  failedToDecryptFile(8),

  /// The contact does not support OMEMO:2.
  omemoNotSupported(9),

  /// The chat is set to use OMEMO, but the received file was sent in plaintext.
  chatEncryptedButPlaintextFile(10),

  /// The encryption of the file somehow failed.
  failedToEncryptFile(11),

  /// We were unable to download the file.
  fileDownloadFailed(12),

  /// The message was bounced with a <service-unavailable />.
  serviceUnavailable(13),

  /// The message was bounced with a <remote-server-timeout />.
  remoteServerTimeout(14),

  /// The message was bounced with a <remote-server-not-found />.
  remoteServerNotFound(15);

  const MessageErrorType(this.value);

  static MessageErrorType? fromInt(int? value) {
    if (value == null) {
      return null;
    }

    if (value == MessageErrorType.unspecified.value) {
      return MessageErrorType.unspecified;
    } else if (value == MessageErrorType.noError.value) {
      return MessageErrorType.noError;
    } else if (value == MessageErrorType.fileUploadFailed.value) {
      return MessageErrorType.fileUploadFailed;
    } else if (value == MessageErrorType.notEncryptedForDevice.value) {
      return MessageErrorType.notEncryptedForDevice;
    } else if (value == MessageErrorType.invalidHMAC.value) {
      return MessageErrorType.invalidHMAC;
    } else if (value == MessageErrorType.noDecryptionKey.value) {
      return MessageErrorType.noDecryptionKey;
    } else if (value == MessageErrorType.invalidAffixElements.value) {
      return MessageErrorType.invalidAffixElements;
    } else if (value == MessageErrorType.failedToEncrypt.value) {
      return MessageErrorType.failedToEncrypt;
    } else if (value == MessageErrorType.failedToDecryptFile.value) {
      return MessageErrorType.failedToDecryptFile;
    } else if (value == MessageErrorType.omemoNotSupported.value) {
      return MessageErrorType.omemoNotSupported;
    } else if (value == MessageErrorType.chatEncryptedButPlaintextFile.value) {
      return MessageErrorType.chatEncryptedButPlaintextFile;
    } else if (value == MessageErrorType.failedToEncryptFile.value) {
      return MessageErrorType.failedToEncryptFile;
    } else if (value == MessageErrorType.fileDownloadFailed.value) {
      return MessageErrorType.fileDownloadFailed;
    } else if (value == MessageErrorType.serviceUnavailable.value) {
      return MessageErrorType.serviceUnavailable;
    } else if (value == MessageErrorType.remoteServerTimeout.value) {
      return MessageErrorType.remoteServerTimeout;
    } else if (value == MessageErrorType.remoteServerNotFound.value) {
      return MessageErrorType.remoteServerNotFound;
    }

    return null;
  }

  static MessageErrorType? fromException(dynamic exception) {
    if (exception == null) {
      return null;
    }

    if (exception is InvalidMessageHMACError) {
      return MessageErrorType.invalidHMAC;
    } else if (exception is NotEncryptedForDeviceError) {
      return MessageErrorType.noDecryptionKey;
    } else if (exception is InvalidAffixElementsException) {
      return MessageErrorType.invalidAffixElements;
    } else if (exception is EncryptionFailedException) {
      return MessageErrorType.failedToEncrypt;
    } else if (exception is OmemoNotSupportedForContactException) {
      return MessageErrorType.omemoNotSupported;
    }

    return MessageErrorType.unspecified;
  }

  /// The identifier representing the error.
  final int value;

  String get translatableString {
    assert(
      this != MessageErrorType.noError,
      'Calling errorToTranslatableString with noError makes no sense',
    );

    switch (this) {
      case MessageErrorType.notEncryptedForDevice:
        return t.errors.omemo.notEncryptedForDevice;
      case MessageErrorType.invalidHMAC:
        return t.errors.omemo.invalidHmac;
      case MessageErrorType.noDecryptionKey:
        return t.errors.omemo.noDecryptionKey;
      case MessageErrorType.invalidAffixElements:
        return t.errors.omemo.messageInvalidAfixElement;
      case MessageErrorType.fileUploadFailed:
        return t.errors.message.fileUploadFailed;
      case MessageErrorType.omemoNotSupported:
        return t.errors.message.contactDoesntSupportOmemo;
      case MessageErrorType.fileDownloadFailed:
        return t.errors.message.fileDownloadFailed;
      case MessageErrorType.serviceUnavailable:
        return t.errors.message.serviceUnavailable;
      case MessageErrorType.remoteServerTimeout:
        return t.errors.message.remoteServerTimeout;
      case MessageErrorType.remoteServerNotFound:
        return t.errors.message.remoteServerNotFound;
      case MessageErrorType.failedToEncrypt:
        return t.errors.message.failedToEncrypt;
      case MessageErrorType.failedToDecryptFile:
        return t.errors.message.failedToDecryptFile;
      case MessageErrorType.chatEncryptedButPlaintextFile:
        return t.errors.message.fileNotEncrypted;
      case MessageErrorType.failedToEncryptFile:
        return t.errors.message.failedToEncryptFile;
      // NOTE: This fallthrough is just here to make Dart happy
      case MessageErrorType.noError:
      case MessageErrorType.unspecified:
        return t.errors.message.unspecified;
    }
  }
}

/// A converter for converting between [MessageErrorType] and [int].
class MessageErrorTypeConverter
    implements JsonConverter<MessageErrorType, int> {
  const MessageErrorTypeConverter();

  @override
  MessageErrorType fromJson(int json) {
    return MessageErrorType.fromInt(json)!;
  }

  @override
  int toJson(MessageErrorType data) => data.value;
}
