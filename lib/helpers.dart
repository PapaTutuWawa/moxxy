import "dart:collection";

/*
 * Add a leading zero, if required, to ensure that an integer is rendered
 * as a two "digit" string.
 *
 * NOTE: This function assumes that 0 <= i <= 99
 */
String padInt(int i) {
  if (i <= 9) {
    return "0" + i.toString();
  }

  return i.toString();
}

/*
 * A wrapper around List<T>.firstWhere that does not throw but instead just
 * returns true if test returns true for an element or false if test never
 * returned true.
 */
bool listContains<T>(List<T> list, bool Function(T element) test) {
  try {
    return list.firstWhere(test) != null;
  } catch(e) {
    return false;
  }
}
