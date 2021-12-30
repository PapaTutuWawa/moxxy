import "dart:collection";

import "package:xml/xml.dart";

class XMLNode {
  final String tag;
  Map<String, dynamic> attributes;
  List<XMLNode> children;
  bool closeTag;
  String? text;

  XMLNode({ required this.tag, required this.attributes, List<XMLNode>? children, this.closeTag = true, this.text }) : children = children ?? List<XMLNode>.empty();
  XMLNode.xmlns({ required this.tag, required String xmlns, Map<String, String>? attributes, List<XMLNode>? children, this.closeTag = true }) : attributes = { "xmlns": xmlns, ...(attributes ?? {}) }, children = children ?? List<XMLNode>.empty();

  void addChild(XMLNode child) {
    this.children.add(child);
  }
  
  String renderAttributes() {
    return this.attributes.keys.map((key) {
        final value = this.attributes[key]!;
        assert(value is String || value is int);
        if (value is String) {
          return "$key='${value}'";
        } else {
          return "$key=${value.toString()}";
        }
    }).join(" ");
  }
  
  String toXml() {
    if (this.text != null) {
      final attrString = this.attributes.isEmpty ? "" : " " + this.renderAttributes();
      return "<${this.tag}${attrString}>${this.text}</${this.tag}>";
    }

    if (this.children.isEmpty) {
      return "<${this.tag} ${this.renderAttributes()}" + (this.closeTag ? " />" : ">");
    }

    final String childXml = this.children.map((child) => child.toXml()).join();
    final xml = "<${this.tag} ${this.renderAttributes()}>${childXml}";
    return xml + (this.closeTag ? "</${this.tag}>" : "");
  }

  XMLNode? firstTag(String tag) {
    try {
      return this.children.firstWhere((node) => node.tag == tag);
    } catch(e) {
      return null;
    }
  }

  List<XMLNode> findTags(String tag) {
    return this.children.where((element) => element.tag == tag).toList();
  }

  String innerText() {
    return this.text ?? "";
  }
  
  // Because this API is better ;)
  static XMLNode fromXmlElement(XmlElement element) {
    Map<String, String> attributes = Map();

    element.attributes.forEach((attribute) {
        attributes[attribute.name.qualified] = attribute.value;
    });

    if (element.childElements.length == 0) {
      return XMLNode(
        tag: element.name.qualified,
        attributes: attributes,
        text: element.innerText
      );
    } else {
      return XMLNode(
        tag: element.name.qualified,
        attributes: attributes,
        children: element.childElements.toList().map((e) => XMLNode.fromXmlElement(e)).toList()
      );
    }
  }
}
