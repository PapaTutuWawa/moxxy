import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
      final suffix = difference >= 364.5 * Duration.millisecondsPerDay
          ? dt.year.toString()
          : '';
      return '${dt.day}.${dt.month}.$suffix';
    } else {
      return '${hourDifference}h';
    }
  } else if (difference <= Duration.millisecondsPerMinute) {
    return t.dateTime.justNow;
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
      return t.dateTime.justNow;
    } else {
      final diff = (difference / Duration.millisecondsPerMinute).floor();
      return t.dateTime.nMinutesAgo(min: diff);
    }
  }
}

/// Turn [day], which is an integer between 1 and 7, into the name of the day of the week.
String weekdayToStringAbbrev(int day) {
  switch (day) {
    case DateTime.monday:
      return t.dateTime.mondayAbbrev;
    case DateTime.tuesday:
      return t.dateTime.tuesdayAbbrev;
    case DateTime.wednesday:
      return t.dateTime.wednessdayAbbrev;
    case DateTime.thursday:
      return t.dateTime.thursdayAbbrev;
    case DateTime.friday:
      return t.dateTime.fridayAbbrev;
    case DateTime.saturday:
      return t.dateTime.saturdayAbbrev;
    case DateTime.sunday:
      return t.dateTime.sundayAbbrev;
  }

  // Should not happen
  throw Exception();
}

/// Turn [month], which is an integer between 1 and 12, into the name of the month.
String monthToString(int month) {
  switch (month) {
    case DateTime.january:
      return t.dateTime.january;
    case DateTime.february:
      return t.dateTime.february;
    case DateTime.march:
      return t.dateTime.march;
    case DateTime.april:
      return t.dateTime.april;
    case DateTime.may:
      return t.dateTime.may;
    case DateTime.june:
      return t.dateTime.june;
    case DateTime.july:
      return t.dateTime.july;
    case DateTime.august:
      return t.dateTime.august;
    case DateTime.september:
      return t.dateTime.september;
    case DateTime.october:
      return t.dateTime.october;
    case DateTime.november:
      return t.dateTime.november;
    case DateTime.december:
      return t.dateTime.december;
  }

  // Should not happen
  throw Exception();
}

/// Format both the timestamp [dt] of the message and the current timestamp into a string
/// like 'Today', 'Yesterday', 'Fri, 7. August' or '6. August 2022'.
String formatDateBubble(DateTime dt, DateTime now) {
  if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
    return t.dateTime.today;
  } else if (now.subtract(const Duration(days: 1)).day == dt.day) {
    return t.dateTime.yesterday;
  } else if (dt.year == now.year) {
    return '${weekdayToStringAbbrev(dt.weekday)}., ${dt.day}. ${monthToString(dt.month)}';
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
    case JidFormatError.empty:
      return 'XMPP-Address cannot be empty';
    case JidFormatError.noSeparator:
    case JidFormatError.tooManySeparators:
      return 'XMPP-Address must contain exactly one @';
    // TODO(Unknown): Find a better text
    case JidFormatError.noDomain:
      return 'A domain must follow the @';
    case JidFormatError.noLocalpart:
      return 'Your username must preceed the @';
    case JidFormatError.none:
      return null;
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
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
  }

  return null;
}

/// Return the translated name describing the MIME type [mime]. If [mime] is null or
/// the MIME type is neither image, video or audio, then it falls back to the
/// translation of "file".
String mimeTypeToName(String? mime) {
  if (mime != null) {
    if (mime.startsWith('image')) {
      return t.messages.image;
    } else if (mime.startsWith('audio')) {
      return t.messages.audio;
    } else if (mime.startsWith('video')) {
      return t.messages.video;
    }
  }

  return t.messages.file;
}

/// Return an emoji for the MIME type [mime]. If [addTypeName] id true, then a human readable
/// name for the MIME type will be appended.
String mimeTypeToEmoji(String? mime, {bool addTypeName = true}) {
  String value;
  if (mime != null) {
    if (mime.startsWith('image')) {
      value = '🖼️';
    } else if (mime.startsWith('audio')) {
      value = '🎙';
    } else if (mime.startsWith('video')) {
      value = '🎬';
    } else {
      value = '📁';
    }
  } else {
    value = '📁';
  }

  if (addTypeName) {
    value += ' ${mimeTypeToName(mime)}';
  }

  return value;
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

/// Return a version of the filename [filename] with [suffix] attached to the file's
/// name while keeping the extension in [filename] intact.
String filenameWithSuffix(String filename, String suffix) {
  final parts = filename.split('.');

  // Handle the special case of no "." in filename
  if (parts.length == 1) {
    return '$filename$suffix';
  }

  final filenameWithoutExtension = parts.take(parts.length - 1).join('.');
  return '$filenameWithoutExtension$suffix.${parts.last}';
}

extension ExceptionSafeLock on Lock {
  /// Throwing an exception with synchronized is not safe as it will cause the lock to
  /// not get released. This function wraps the call to [criticalSection], making sure
  /// that it cannot deadlock everything depending on the lock. Throws the exception again
  /// after the lock has been released.
  /// With [log], one can control how the stack trace gets displayed. Defaults to print.
  Future<void> safeSynchronized(
    Future<void> Function() criticalSection, {
    void Function(String) log = print,
  }) async {
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

/// Load [path] into memory and determine its width and height. Returns null in case
/// of an error.
Future<Size?> getImageSizeFromPath(String path) async {
  final bytes = await File(path).readAsBytes();
  return getImageSizeFromData(bytes);
}

/// Like getImageSizeFromPath but taking the image's bytes directly.
Future<Size?> getImageSizeFromData(Uint8List bytes) async {
  try {
    final dartCodec = await instantiateImageCodec(bytes);
    final dartFrame = await dartCodec.getNextFrame();

    final size = Size(
      dartFrame.image.width.toDouble(),
      dartFrame.image.height.toDouble(),
    );

    dartFrame.image.dispose();
    dartCodec.dispose();

    return size;
  } catch (_) {
    // TODO(PapaTutuWawa): Log error
    return null;
  }
}

/// Generate a thumbnail file (JPEG) for the video at [path]. [conversationJid] refers
/// to the JID of the conversation the file comes from.
/// If the thumbnail already exists, then just its path is returned. If not, then
/// it gets generated first.
Future<String?> getVideoThumbnailPath(
  String path,
  String conversationJid,
  String mime,
) async {
  //print('getVideoThumbnailPath: Mime type: $mime');

  // Ignore mime types that may be wacky
  if (mime == 'video/webm') return null;

  final tempDir = await getTemporaryDirectory();
  final thumbnailFilenameNoExtension = p.withoutExtension(
    p.basename(path),
  );
  final thumbnailFilename = '$thumbnailFilenameNoExtension.jpg';
  final thumbnailDirectory = p.join(
    tempDir.path,
    'thumbnails',
    conversationJid,
  );
  final thumbnailPath = p.join(thumbnailDirectory, thumbnailFilename);

  final dir = Directory(thumbnailDirectory);
  if (!dir.existsSync()) await dir.create(recursive: true);
  final file = File(thumbnailPath);
  if (file.existsSync()) return thumbnailPath;

  final r = await VideoThumbnail.thumbnailFile(
    video: path,
    thumbnailPath: thumbnailDirectory,
    imageFormat: ImageFormat.JPEG,
    quality: 75,
  );
  assert(
    r == thumbnailPath,
    'The generated video thumbnail has a different path than we expected: $r vs. $thumbnailPath',
  );

  return thumbnailPath;
}

Future<String> getContactProfilePicturePath(String id) async {
  final tempDir = await getTemporaryDirectory();
  final avatarDir = p.join(
    tempDir.path,
    'contacts',
    'avatars',
  );
  final dir = Directory(avatarDir);
  if (!dir.existsSync()) await dir.create(recursive: true);

  return p.join(avatarDir, id);
}

Future<String> getStickerPackPath(String hashFunction, String hashValue) async {
  final appDir = await getApplicationDocumentsDirectory();
  return p.join(
    appDir.path,
    'stickers',
    '${hashFunction}_$hashValue',
  );
}

/// Prepend [item] to [list], but ensure that the resulting list's size is
/// smaller than or equal to [maxSize].
List<T> clampedListPrepend<T>(List<T> list, T item, int maxSize) {
  return clampedListPrependAll(
    list,
    [item],
    maxSize,
  );
}

/// Prepend [items] to [list], but ensure that the resulting list has a size
/// that is smaller than or equal to [maxSize].
List<T> clampedListPrependAll<T>(List<T> list, List<T> items, int maxSize) {
  if (items.length >= maxSize) {
    return items.sublist(0, maxSize);
  }

  if (list.length + items.length <= maxSize) {
    return [
      ...items,
      ...list,
    ];
  }

  return [
    ...items,
    ...list,
  ].sublist(0, maxSize);
}

extension StringJsonHelper on String {
  /// Converts the Map into a JSON-encoded String. Helper function for working with nullable maps.
  Map<String, dynamic> fromJson() {
    return (jsonDecode(this) as Map<dynamic, dynamic>).cast<String, dynamic>();
  }
}

extension MapJsonHelper on Map<String, dynamic> {
  /// Converts the map into a String. Helper function for working with nullable Strings.
  String toJson() => jsonEncode(this);
}
