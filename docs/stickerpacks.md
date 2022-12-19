# Sticker Packs

Moxxy supports sending and receiving sticker packs using XEP-0449 version 0.1.1. Sticker
packs can also be imported using a Moxxy specific format.

## File Format

A Moxxy sticker pack is a flat tar archive that contains the following files:

- `urn.xmpp.stickers.0.xml`
- The sticker files

### `urn.xmpp.stickers.0.xml`

This file is the sticker pack's metadata file. It describes the sticker pack the same
way as the examples in XEP-0449 do. There are, however, some differences:

- Each `<file />` element must contain a `<name />` element that matches with a file in the tar archive
- Each sticker MUST contain at least one HTTP(s) source
- The `<hash />` of the `<pack />` element is ignored as Moxxy computes it itself, so it can be omitted

An example for the metadata file is the following:

```xml
<pack xmlns='urn:xmpp:stickers:0'>
    <name>Example</name>
    <summary>Example sticker pack.</summary>
    <item>
        <file xmlns='urn:xmpp:file:metadata:0'>
            <media-type>image/png</media-type>
            <desc>:some-sticker:</desc>
            <name>suprise.png</name>
            <size>531910</size>
            <dimensions>1030x1030</dimensions>
            <hash xmlns='urn:xmpp:hashes:2' algo='sha-256'>1Ha4okUGNRAA04KibwWUmklqqBqdhg7+20dfsr/wLik=</hash>
        </file>
        <sources xmlns='urn:xmpp:sfs:0'>
            <url-data xmlns='http://jabber.org/protocol/url-data' target='...' />
        </sources>
    </item>
	<!-- ... -->
</pack>
```
