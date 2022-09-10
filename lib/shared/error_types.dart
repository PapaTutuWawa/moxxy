import 'package:omemo_dart/omemo_dart.dart';

const noError = 0;
const fileUploadFailedError = 1;
const messageNotEncryptedForDevice = 2;
const messageInvalidHMAC = 3;
const messageNoDecryptionKey = 4;

int errorTypeFromException(dynamic exception) {
  if (exception is NoDecryptionKeyException) {
    return messageNoDecryptionKey;
  } else if (exception is InvalidMessageHMACException) {
    return messageInvalidHMAC;
  } else if (exception is NotEncryptedForDeviceException) {
    return messageNoDecryptionKey;
  }

  return noError;
}
