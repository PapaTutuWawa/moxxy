import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:moxxyv2/shared/logging.dart';
import 'package:test/test.dart';

void main() {
  test('Test encryption', () async {
    // Simple test vector verified with the monal UDP log server
    final bytes = await encryptData(
      utf8.encode('Hallo Welt'),
      await deriveKey('abc123'),
      nonce: utf8.encode('123456789012'),
    );
    expect(
      HEX.encode(bytes),
      '313233343536373839303132423bfd17513c578952bf0cb217aabc9e615c4633883034d013a9',
    );
  });
}
