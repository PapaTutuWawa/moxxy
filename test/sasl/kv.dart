import "package:moxxyv2/xmpp/sasl/kv.dart";

import "package:test/test.dart";

void main() {
  test("Test the Key-Value parser", () {
      final result1 = parseKeyValue("n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL");
      expect(result1.length, 2);
      expect(result1["n"]!, "user");
      expect(result1["r"]!, "fyko+d2lbbFgONRv9qkxdawL");

      final result2 = parseKeyValue("r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096");
      expect(result2.length, 3);
      expect(result2["r"]!, "fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j");
      expect(result2["s"]!, "QSXCR+Q6sek8bf92");
      expect(result2["i"]!, "4096");
  });

  test("Test the Key-Value parser with '=' as a value", () {
      final result = parseKeyValue("c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts=,o=123");
      expect(result.length, 4);
      expect(result["c"]!, "biws");
      expect(result["r"]!, "fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j");
      expect(result["p"]!, "v0X8v3Bz2T0CJGbJQyF0X+HI4Ts=");
      expect(result["o"]!, "123");
  });
}
