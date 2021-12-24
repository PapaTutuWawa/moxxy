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
