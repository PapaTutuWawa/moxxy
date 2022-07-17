/// A wrapper class that can be used to indicate that a function may return a valid
/// instance of [T] but may also fail.
/// The way [MayFail] is intended to be used to to have function specific - or application
/// specific - error codes that can be either handled by code or be translated into a
/// localised error message for the user.
class MayFail<T> {

  MayFail({ this.result, this.errorCode });
  MayFail.success(this.result);
  MayFail.failure(this.errorCode);
  T? result;
  int? errorCode;

  bool isError() => result == null && errorCode != null;

  T getValue() => result!;

  int getErrorCode() => errorCode!;
}
