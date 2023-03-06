import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:omemo_dart/omemo_dart.dart';

const unspecifiedError = -1;
const noError = 0;
const fileUploadFailedError = 1;
const messageNotEncryptedForDevice = 2;
const messageInvalidHMAC = 3;
const messageNoDecryptionKey = 4;
const messageInvalidAffixElements = 5;
// const messageInvalidNumber = 6;
const messageFailedToEncrypt = 7;
const messageFailedToDecryptFile = 8;
const messageContactDoesNotSupportOmemo = 9;
const messageChatEncryptedButFileNot = 10;
const messageFailedToEncryptFile = 11;
const fileDownloadFailedError = 12;
const messageServiceUnavailable = 13;
const messageRemoteServerTimeout = 14;
const messageRemoteServerNotFound = 15;

int errorTypeFromException(dynamic exception) {
  if (exception == null) {
    return noError;
  }

  if (exception is NoDecryptionKeyException) {
    return messageNoDecryptionKey;
  } else if (exception is InvalidMessageHMACException) {
    return messageInvalidHMAC;
  } else if (exception is NotEncryptedForDeviceException) {
    return messageNoDecryptionKey;
  } else if (exception is InvalidAffixElementsException) {
    return messageInvalidAffixElements;
  } else if (exception is EncryptionFailedException) {
    return messageFailedToEncrypt;
  } else if (exception is OmemoNotSupportedForContactException) {
    return messageContactDoesNotSupportOmemo;
  }

  return unspecifiedError;
}

String errorToTranslatableString(int error) {
  assert(
    error != noError,
    'Calling errorToTranslatableString with noError makes no sense',
  );

  switch (error) {
    case messageNotEncryptedForDevice:
      return t.errors.omemo.notEncryptedForDevice;
    case messageInvalidHMAC:
      return t.errors.omemo.invalidHmac;
    case messageNoDecryptionKey:
      return t.errors.omemo.noDecryptionKey;
    case messageInvalidAffixElements:
      return t.errors.omemo.messageInvalidAfixElement;
    case fileUploadFailedError:
      return t.errors.message.fileUploadFailed;
    case messageContactDoesNotSupportOmemo:
      return t.errors.message.contactDoesntSupportOmemo;
    case fileDownloadFailedError:
      return t.errors.message.fileDownloadFailed;
    case messageServiceUnavailable:
      return t.errors.message.serviceUnavailable;
    case messageRemoteServerTimeout:
      return t.errors.message.remoteServerTimeout;
    case messageRemoteServerNotFound:
      return t.errors.message.remoteServerNotFound;
    case messageFailedToEncrypt:
      return t.errors.message.failedToEncrypt;
    case messageFailedToDecryptFile:
      return t.errors.message.failedToDecryptFile;
    case messageChatEncryptedButFileNot:
      return t.errors.message.fileNotEncrypted;
    case messageFailedToEncryptFile:
      return t.errors.message.failedToEncryptFile;
    case unspecifiedError:
      return t.errors.message.unspecified;
  }

  assert(false, 'Invalid error code $error used');
  return '';
}
