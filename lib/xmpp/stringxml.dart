import 'package:xml/xml.dart';

class XMLNode {

  XMLNode({
      required this.tag,
      this.attributes = const {},
      this.children = const [],
      this.closeTag = true,
      this.text,
      this.isDeclaration = false,
  });
  XMLNode.xmlns({
      required this.tag,
      required String xmlns,
      Map<String, String> attributes = const {},
      this.children = const [],
      this.closeTag = true,
      this.text,
  }) : attributes = { 'xmlns': xmlns, ...attributes }, isDeclaration = false;
  /// Because this API is better ;)
  /// Don't use in production. Just for testing
  factory XMLNode.fromXmlElement(XmlElement element) {
    final attributes = <String, String>{};

    for (final attribute in element.attributes) {
      attributes[attribute.name.qualified] = attribute.value;
    }

    if (element.childElements.isEmpty) {
      return XMLNode(
        tag: element.name.qualified,
        attributes: attributes,
        text: element.innerText,
      );
    } else {
      return XMLNode(
        tag: element.name.qualified,
        attributes: attributes,
        children: element.childElements.toList().map(XMLNode.fromXmlElement).toList(),
      );
    }
  }
  /// Just for testing purposes
  factory XMLNode.fromString(String str) {
    return XMLNode.fromXmlElement(
      XmlDocument.parse(str).firstElementChild!,
    );
  }
  final String tag;
  Map<String, dynamic> attributes;
  List<XMLNode> children;
  bool closeTag;
  String? text;
  bool isDeclaration;

  /// Adds a child to this node.
  void addChild(XMLNode child) {
    children.add(child);
  }

  /// Renders the attributes of the node into "attr1=\"value\" attr2=...".
  String renderAttributes() {
    return attributes.keys.map((String key) {
        final dynamic value = attributes[key];
        assert(value is String || value is int, 'XML values must either be string or int');
        if (value is String) {
          return "$key='$value'";
        } else {
          return '$key=$value';
        }
    }).join(' ');
  }

  /// Renders the entire node, including its children, into an XML string.
  String toXml() {
    final decl = isDeclaration ? '?' : '';
    if (children.isEmpty) {
      if (text != null && text!.isNotEmpty) {
        final attrString = attributes.isEmpty ? '' : ' ${renderAttributes()}';
        return '<$tag$attrString>$text</$tag>';
      } else {
        return '<$decl$tag ${renderAttributes()}${closeTag ? " />" : "$decl>"}';
      } 
    } else { 
      final childXml = children.map((child) => child.toXml()).join();
      final xml = '<$decl$tag ${renderAttributes()}$decl>$childXml';
      return xml + (closeTag ? '</$tag>' : '');
    }
  }

  /// Returns the first child for which [test] returns true. If none is found, returns
  /// null.
  XMLNode? _firstTag(bool Function(XMLNode) test) {
    try {
      return children.firstWhere(test);
    } catch(e) {
      return null;
    }
  }
  
  /// Returns the first xml node that matches the description:
  /// - node's tag is equal to [tag]
  /// - (optional) node's xmlns attribute is equal to [xmlns]
  /// Returns null if none is found.
  XMLNode? firstTag(String tag, { String? xmlns}) {
    return _firstTag((node) {
      if (xmlns != null) {
        return node.tag == tag && node.attributes['xmlns'] == xmlns;
      }

      return node.tag == tag;
    });
  }

  /// Returns the first child whose xmlns attribute is equal to [xmlns]. Returns null
  /// if none is found.
  XMLNode? firstTagByXmlns(String xmlns) {
    return _firstTag((node) {
      return node.attributes['xmlns'] == xmlns;
    });
  }
  
  /// Returns all children whose tag is equal to [tag].
  List<XMLNode> findTags(String tag, { String? xmlns }) {
    return children.where((element) {
      final xmlnsMatches = xmlns != null ? element.attributes['xmlns'] == xmlns : true;
      return element.tag == tag && xmlnsMatches;
    }).toList();
  }
  
  /// Returns the inner text of the node. If none is set, returns the "".
  String innerText() {
    return text ?? '';
  }
}
