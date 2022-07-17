import 'dart:async';

import 'package:moxxyv2/xmpp/buffer.dart';

import 'package:test/test.dart';

void main() {
  test('Test non-broken up Xml data', () async {
    var childa = false;
    var childb = false;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    controller
      .stream
      .transform(buffer)
      .forEach((node) {
        if (node.tag == 'childa') {
          childa = true;
        } else if (node.tag == 'childb') {
          childb = true;
        }
      });
    controller.add('<childa /><childb />');

    await Future.delayed(const Duration(seconds: 2), () {
      expect(childa, true);
      expect(childb, true);
    });
  });
  test('Test broken up Xml data', () async {
    var childa = false;
    var childb = false;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    controller
      .stream
      .transform(buffer)
      .forEach((node) {
        if (node.tag == 'childa') {
          childa = true;
        } else if (node.tag == 'childb') {
          childb = true;
        }
      });
    controller.add('<childa');
    controller.add(' /><childb />');

    await Future.delayed(const Duration(seconds: 2), () {
      expect(childa, true);
      expect(childb, true);
    });
  });

  test('Test closing the stream', () async {
    var childa = false;
    var childb = false;

    final buffer = XmlStreamBuffer();
    final controller = StreamController<String>();

    controller
      .stream
      .transform(buffer)
      .forEach((node) {
        if (node.tag == 'childa') {
          childa = true;
        } else if (node.tag == 'childb') {
          childb = true;
        }
      });
    controller.add('<childa');
    controller.add(' /><childb />');
    controller.add('</stream:stream>');

    await Future.delayed(const Duration(seconds: 2), () {
      expect(childa, true);
      expect(childb, true);
    });
  });
}
