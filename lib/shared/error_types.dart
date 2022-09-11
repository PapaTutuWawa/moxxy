import 'package:moxxyv2/xmpp/xeps/xep_0384/errors.dart';
import 'package:omemo_dart/omemo_dart.dart';

const noError = 0;
const fileUploadFailedError = 1;
const messageNotEncryptedForDevice = 2;
const messageInvalidHMAC = 3;
const messageNoDecryptionKey = 4;
const messageInvalidAffixElements = 5;

int errorTypeFromException(dynamic exception) {
  if (exception is NoDecryptionKeyException) {
    return messageNoDecryptionKey;
  } else if (exception is InvalidMessageHMACException) {
    return messageInvalidHMAC;
  } else if (exception is NotEncryptedForDeviceException) {
    return messageNoDecryptionKey;
  } else if (exception is InvalidAffixElementsException) {
    return messageInvalidAffixElements;
  }

  return noError;
}
