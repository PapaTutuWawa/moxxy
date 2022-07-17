import 'package:moxxyv2/xmpp/xeps/xep_0363.dart';

import 'package:test/test.dart';

void main() {
  group('Test the XEP-0363 header preparation', () {
      test('invariance', () {
          final headers = {
            'authorization': 'Basic Base64String==',
            'cookie': 'foo=bar; user=romeo'
          };
          expect(
            prepareHeaders(headers),
            headers,
          );
      });
      test('invariance through uppercase', () {
          final headers = {
            'Authorization': 'Basic Base64String==',
            'Cookie': 'foo=bar; user=romeo'
          };
          expect(
            prepareHeaders(headers),
            headers,
          );
      });
      test('remove unspecified headers', () {
          final headers = {
            'Authorization': 'Basic Base64String==',
            'Cookie': 'foo=bar; user=romeo',
            'X-Tracking': 'Base64String=='
          };
          expect(
            prepareHeaders(headers),
            {
              'Authorization': 'Basic Base64String==',
              'Cookie': 'foo=bar; user=romeo',
            }
          );
      });
      test('remove newlines', () {
          final headers = {
            'Authorization': '\n\nBasic Base64String==\n\n',
            '\nCookie\r\n': 'foo=bar; user=romeo',
          };
          expect(
            prepareHeaders(headers),
            {
              'Authorization': 'Basic Base64String==',
              'Cookie': 'foo=bar; user=romeo',
            }
          );
      });
  });
}
