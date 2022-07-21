import 'dart:core';

import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

/// Add a leading zero, if required, to ensure that an integer is rendered
/// as a two "digit" string.
///
/// NOTE: This function assumes that 0 <= i <= 99
String padInt(int i) {
  if (i <= 9) {
    return '0$i';
  }

  return i.toString();
}

/// A wrapper around List<T>.firstWhere that does not throw but instead just
/// returns true if [test] returns true for an element or false if [test] never
/// returned true.
bool listContains<T>(List<T> list, bool Function(T element) test) {
  return firstWhereOrNull<T>(list, test) != null;
}

/// A wrapper around [List<T>.firstWhere] that does not throw but instead just
/// return null if [test] never returned true
T? firstWhereOrNull<T>(List<T> list, bool Function(T element) test) {
  try {
    return list.firstWhere(test);
  } catch(e) {
    return null;
  }
}

/// Format the timestamp of a conversation change into a nice string.
/// timestamp and now are both in millisecondsSinceEpoch.
/// Ensures that now >= timestamp
String formatConversationTimestamp(int timestamp, int now) {
  final difference = now - timestamp;

  // NOTE: Just to make sure
  assert(difference >= 0, 'Timestamp lies in the future');

  if (difference >= 60 * Duration.millisecondsPerMinute) {
    final hourDifference = (difference / Duration.millisecondsPerHour).floor();
    if (hourDifference >= 24) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final suffix = difference >= 364.5 * Duration.millisecondsPerDay ? dt.year.toString() : '';
      return '${dt.day}.${dt.month}.$suffix'; 
    } else {
      return '${hourDifference}h';
    }
  } else if (difference <= Duration.millisecondsPerMinute) {
    return 'Just now';
  }

  return '${(difference / Duration.millisecondsPerMinute).floor()}min';
}

/// Same as [formatConversationTimestamp] but for messages
String formatMessageTimestamp(int timestamp, int now) {
  final difference = now - timestamp;

  // NOTE: Just to make sure
  assert(difference >= 0, 'Timestamp lies in the future');

  if (difference >= 15 * Duration.millisecondsPerMinute) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour}:${padInt(dt.minute)}';
  } else {
    if (difference < Duration.millisecondsPerMinute) {
      return 'Just now';
    } else {
      return '${(difference / Duration.millisecondsPerMinute).floor()}min ago';
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

/// Validate a JID and return why it is invalid.
JidFormatError validateJid(String jid) {
  if (jid.isEmpty) {
    return JidFormatError.empty;
  }

  if (!jid.contains('@')) {
    return JidFormatError.noSeparator;
  }

  final parts = jid.split('@');
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

/// Returns an error string if [jid] is not a valid JID. Returns null if everything
/// appears okay.
String? validateJidString(String jid) {
  switch (validateJid(jid)) {
    case JidFormatError.empty: return 'XMPP-Address cannot be empty';
    case JidFormatError.noSeparator:
    case JidFormatError.tooManySeparators: return 'XMPP-Address must contain exactly one @';
    // TODO(Unknown): Find a better text
    case JidFormatError.noDomain: return 'A domain must follow the @';
    case JidFormatError.noLocalpart: return 'Your username must preceed the @';
    case JidFormatError.none: return null;
  }
}

/// Returns the first element in [items] which is non null.
/// Returns null if they all are null.
T? firstNotNull<T>(List<T?> items) {
  for (final item in items) {
    if (item != null) return item;
  }

  return null;
}

/// Attempt to guess a mimetype from its file extension
String? guessMimeTypeFromExtension(String ext) {
  switch (ext) {
    case 'png': return 'image/png';
    case 'jpg':
    case 'jpeg': return 'image/jpeg';
    case 'webp': return 'image/webp';
    case 'mp4': return 'video/mp4';
  }

  return null;
}

/// Show a combinatio of an emoji and its file type
String mimeTypeToConversationBody(String? mime) {
  if (mime != null) {
    if (mime.startsWith('image/')) {
      return '📷 Image';
    } else if (mime.startsWith('video/')) {
      return '🎞️ Video';
    } else if (mime.startsWith('audio/')) {
      return '🎵 Audio';
    }
  }

  return '📁 File';
}

/// Parse an Uri and return the "filename".
String filenameFromUrl(String url) {
  return Uri.parse(url).pathSegments.last;
}

ChatState chatStateFromString(String raw) {
  switch(raw) {
    case 'active': {
      return ChatState.active;
    }
    case 'composing': {
      return ChatState.composing;
    } 
    case 'paused': {
      return ChatState.paused;
    }
    case 'inactive': {
      return ChatState.inactive;
    }
    case 'gone': {
      return ChatState.gone;
    }
    default: {
      return ChatState.gone;
    }
  }
}

String chatStateToString(ChatState state) => state.toString().split('.').last;

/// Return a version of the filename [filename] with [suffix] attached to the file's
/// name while keeping the extension in [filename] intact.
String filenameWithSuffix(String filename, String suffix) {
  final parts = filename.split('.');

  // Handle the special case of no "." in filename
  if (parts.length == 1) {
    return '$filename$suffix';
  }

  final filenameWithoutExtension = parts
    .take(parts.length - 1)
    .join('.');
  return '$filenameWithoutExtension$suffix.${parts.last}';
}
