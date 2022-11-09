import 'package:moxxmpp/moxxmpp.dart';
import 'package:omemo_dart/omemo_dart.dart';

const noError = 0;
const fileUploadFailedError = 1;
const messageNotEncryptedForDevice = 2;
const messageInvalidHMAC = 3;
const messageNoDecryptionKey = 4;
const messageInvalidAffixElements = 5;
const messageInvalidNumber = 6;
const messageFailedToEncrypt = 7;
const messageFailedToDecryptFile = 8;
const messageContactDoesNotSupportOmemo = 9;
const messageChatEncryptedButFileNot = 10;
const messageFailedToEncryptFile = 11;
const fileDownloadFailedError = 12;

int errorTypeFromException(dynamic exception) {
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

  return noError;
}
