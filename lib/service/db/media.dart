import 'package:isar/isar.dart';

part 'media.g.dart';

@Collection()
@Name('SharedMedium')
class DBSharedMedium {
  int? id;

  @Index(caseSensitive: true)
  late String path;

  late String? mime;

  // The timestamp of the corresponding message
  late int timestamp;
}
