import "dart:collection";

class XMLNode {
  final String tag;
  Map<String, dynamic> attributes;
  List<XMLNode> children;
  // TODO
  bool closeTag;

  XMLNode({ required this.tag, required this.attributes, List<XMLNode>? children, this.closeTag = true }) : children = children ?? List<XMLNode>.empty();
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
    if (this.children.isEmpty) {
      return "<${this.tag} ${this.renderAttributes()}" + (this.closeTag ? " />" : ">");
    }

    final String childXml = this.children.map((child) => child.toXml()).join();
    final xml = "<${this.tag} ${this.renderAttributes()}>${childXml}";
    return xml + (this.closeTag ? "</${this.tag}>" : "");
  }
}

class RawTextNode extends XMLNode {
  final String text;

  RawTextNode({ required this.text }) : super(
    tag: "",
    attributes: {}
  );

  @override
  String toXml() {
    return this.text;
  }
}
