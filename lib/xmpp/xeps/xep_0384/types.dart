/// A simple wrapper class for defining elements that should not be encrypted.
class DoNotEncrypt {

  const DoNotEncrypt(this.tag, this.xmlns);
  final String tag;
  final String xmlns;
}
