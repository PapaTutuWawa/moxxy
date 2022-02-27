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
  return firstWhereOrNull<T>(list, test) != null;
}

/*
 * A wrapper around List<T>.firstWhere that does not throw but instead just
 * return null if test never returned true
 */
T? firstWhereOrNull<T>(List<T> list, bool Function(T element) test) {
  try {
    return list.firstWhere(test);
  } catch(e) {
    return null;
  }
}

/*
 * Format the timestamp of a conversation change into a nice string.
 * timestamp and now are both in millisecondsSinceEpoch.
 * Ensures that now >= timestamp
 */
String formatConversationTimestamp(int timestamp, int now) {
  int difference = now - timestamp;

  // NOTE: Just to make sure
  assert(difference >= 0);

  if (difference >= 60 * Duration.millisecondsPerMinute) {
    int hourDifference = (difference / Duration.millisecondsPerHour).floor();
    if (hourDifference >= 24) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      String suffix = difference >= 364.5 * Duration.millisecondsPerDay ? dt.year.toString() : "";
      return dt.day.toString() + "." + dt.month.toString() + "." + suffix; 
    } else {
      return hourDifference.toString() + "h";
    }
  } else if (difference <= Duration.millisecondsPerMinute) {
    return "Just now";
  }

  return (difference / Duration.millisecondsPerMinute).floor().toString() + "min";
}

/*
 * Same as formatConversationTimestamp but for messages
 */
String formatMessageTimestamp(int timestamp, int now) {
  int difference = now - timestamp;

  // NOTE: Just to make sure
  assert(difference >= 0);

  if (difference >= 15 * Duration.millisecondsPerMinute) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return dt.hour.toString() + ":" + padInt(dt.minute);
  } else {
    if (difference < Duration.millisecondsPerMinute) {
      return "Just now";
    } else {
      return (difference / Duration.millisecondsPerMinute).floor().toString() + "min ago";
    }
  }
}

enum JidFormatError {
  none,
  empty,
  noLocalpart,
  noSeparator,
  tooManySeparators,
  noDomain
}

/*
 * Validate a JID and return why it is invalid
 */
JidFormatError validateJid(String jid) {
  if (jid.isEmpty) {
    return JidFormatError.empty;
  }

  if (!jid.contains("@")) {
    return JidFormatError.noSeparator;
  }

  List<String> parts = jid.split("@");
  if (parts.length != 2) {
    return JidFormatError.tooManySeparators;
  }

  if (parts[0].isEmpty) {
    return JidFormatError.noLocalpart;
  }

  if (parts[1].isEmpty) {
    return JidFormatError.noDomain;
  }

  return JidFormatError.none;
}

/// Returns the first element in [items] which is non null.
/// Returns null if they all are null.
T? firstNotNull<T>(List<T?> items) {
  for (final item in items) {
    if (item != null) return item;
  }

  return null;
}
