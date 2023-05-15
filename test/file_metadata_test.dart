import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:test/test.dart';

void main() {
  test('Test serializing and deserializing hash maps', () {
    final map = {
      HashFunction.sha256: 'hash1',
      HashFunction.sha512: 'hash2',
      HashFunction.blake2b512: 'hash3',
    };

    expect(
      deserializeHashMap(serializeHashMap(map)),
      map,
    );
  });
}
