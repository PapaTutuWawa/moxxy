import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0447.dart';
import 'package:test/test.dart';

void main() {
  test('Test correct SFS parsing', () {
    final sfs = StatelessFileSharingData.fromXML(
      // Taken from https://xmpp.org/extensions/xep-0447.html#file-sharing
      XMLNode.fromString('''
  <file-sharing xmlns='urn:xmpp:sfs:0' disposition='inline'>
    <file xmlns='urn:xmpp:file:metadata:0'>
      <media-type>image/jpeg</media-type>
      <name>summit.jpg</name>
      <size>3032449</size>
      <dimensions>4096x2160</dimensions>
      <hash xmlns='urn:xmpp:hashes:2' algo='sha3-256'>2XarmwTlNxDAMkvymloX3S5+VbylNrJt/l5QyPa+YoU=</hash>
      <hash xmlns='urn:xmpp:hashes:2' algo='id-blake2b256'>2AfMGH8O7UNPTvUVAM9aK13mpCY=</hash>
      <desc>Photo from the summit.</desc>
      <thumbnail xmlns='urn:xmpp:thumbs:1' uri='cid:sha1+ffd7c8d28e9c5e82afea41f97108c6b4@bob.xmpp.org' media-type='image/png' width='128' height='96'/>
    </file>
    <sources>
      <url-data xmlns='http://jabber.org/protocol/url-data' target='https://download.montague.lit/4a771ac1-f0b2-4a4a-9700-f2a26fa2bb67/summit.jpg' />
      <jinglepub xmlns='urn:xmpp:jinglepub:1' from='romeo@montague.lit/resource' id='9559976B-3FBF-4E7E-B457-2DAA225972BB'>
        <description xmlns='urn:xmpp:jingle:apps:file-transfer:5' />
      </jinglepub>
    </sources>
  </file-sharing>
      '''),
    );

    expect(sfs.metadata.hashes['sha3-256'], '2XarmwTlNxDAMkvymloX3S5+VbylNrJt/l5QyPa+YoU=');
    expect(sfs.metadata.hashes['id-blake2b256'], '2AfMGH8O7UNPTvUVAM9aK13mpCY=');
  });
}
