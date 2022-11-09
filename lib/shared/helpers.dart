import 'dart:core';

import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:synchronized/synchronized.dart';

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

/// Turn [day], which is an integer between 1 and 7, into the name of the day of the week.
String weekdayToStringAbbrev(int day) {
  switch (day) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
  }

  // Should not happen
  throw Exception();
}

/// Turn [month], which is an integer between 1 and 12, into the name of the month.
String monthToString(int month) {
  switch (month) {
    case DateTime.january:
      return 'January';
    case DateTime.february:
      return 'February';
    case DateTime.march:
      return 'March';
    case DateTime.april:
      return 'April';
    case DateTime.may:
      return 'May';
    case DateTime.june:
      return 'June';
    case DateTime.july:
      return 'July';
    case DateTime.august:
      return 'August';
    case DateTime.september:
      return 'September';
    case DateTime.october:
      return 'October';
    case DateTime.november:
      return 'November';
    case DateTime.december:
      return 'December';
  }

  // Should not happen
  throw Exception();
}

/// Format both the timestamp [dt] of the message and the current timestamp into a string
/// like 'Today', 'Yesterday', 'Fri, 7. August' or '6. August 2022'.
String formatDateBubble(DateTime dt, DateTime now) {
  if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
    return 'Today';
  } else if (now.subtract(const Duration(days: 1)).day == dt.day) {
    return 'Yesterday';
  } else if (dt.year == now.year) {
    return '${weekdayToStringAbbrev(dt.weekday)}, ${dt.day}. ${monthToString(dt.month)}';
  } else {
    return '${dt.day}. ${monthToString(dt.month)} ${dt.year}';
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

/// Return an emoji for the MIME type [mime]. If [addTypeName] id true, then a human readable
/// name for the MIME type will be appended.
String mimeTypeToEmoji(String? mime, {bool addTypeName = true}) {
  if (mime != null) {
    if (mime.startsWith('image')) {
      return '🖼️${addTypeName ?  " Image" : ""}';
    } else if (mime.startsWith('audio')) {
      return '🎙${addTypeName ?  " Audio" : ""}';
    } else if (mime.startsWith('video')) {
      return '🎬${addTypeName ?  " Video" : ""}';
    }
  }
  return '📁${addTypeName ?  " File" : ""}';
}

/// Parse an Uri and return the "filename".
String filenameFromUrl(String url) {
  return Uri.parse(url).pathSegments.last;
}

/// Attempts to escape [filename] such that it cannot be expanded into another path, i.e.
/// make "../" not dangerous.
String escapeFilename(String filename) {
  return filename
    .replaceAll('/', '%2F')
    // ignore: use_raw_strings
    .replaceAll('\\', '%5C')
    .replaceAll('../', '..%2F');
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

extension ExceptionSafeLock on Lock {
  /// Throwing an exception with synchronized is not safe as it will cause the lock to
  /// not get released. This function wraps the call to [criticalSection], making sure
  /// that it cannot deadlock everything depending on the lock. Throws the exception again
  /// after the lock has been released.
  /// With [log], one can control how the stack trace gets displayed. Defaults to print.
  Future<void> safeSynchronized(Future<void> Function() criticalSection, { void Function(String) log = print }) async {
    Object? ex;

    await synchronized(() async {
      try {
        await criticalSection();
      } catch (err, stackTrace) {
        ex = err;
        log(stackTrace.toString());
      }
    });

    if (ex != null) {
      // ignore: only_throw_errors
      throw ex!;
    }
  }
}

/// Returns true if the message [message] was sent by us ([jid]). If not, returns false.
bool isSent(Message message, String jid) {
  // TODO(PapaTutuWawa): Does this work?
  return message.sender.split('/').first == jid.split('/').first;
}

/// Convert the file size [size] in bytes to a human readable string. This is what
/// Conversations does.
String fileSizeToString(int size) {
  // See https://github.com/iNPUTmice/Conversations/blob/d435c1f2aef1454141d4f5099224b5a03d579dba/src/main/java/eu/siacs/conversations/utils/UIHelper.java#L605
  if (size > (1.5 * 1024 * 1024)) {
    return '${(size * 1.0 / (1024 * 1024)).round()} MiB';
  } else if (size >= 1024) {
    return '${(size * 1.0 / 1024).round()} KiB';
  } else {
    return '$size B';
  }
}
