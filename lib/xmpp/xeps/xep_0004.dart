import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class DataFormOption {
  final String? label;
  final String value;

  const DataFormOption({ required this.value, this.label });

  XMLNode toXml() {
    return XMLNode(
      tag: "option",
      attributes: label != null ? { "label": label } : {},
      children: [
        XMLNode(
          tag: "value",
          text: value
        )
      ]
    );
  }
}

class DataFormField {
  final String? description;
  final bool isRequired;
  final List<String> values;
  final List<DataFormOption> options;
  final String? type;
  final String? varAttr;
  final String? label;

  const DataFormField({
      required this.options,
      required this.values,
      required this.isRequired,
      this.varAttr,
      this.type,
      this.description,
      this.label
  });

  XMLNode toXml() {
    return XMLNode(
      tag: "field",
      attributes: {
        ...(varAttr != null ? { "var": varAttr } : {}),
        ...(type != null ? { "type": type } : {}),
        ...(label != null ? { "label": label } : {})
      },
      children: [
        ...(description != null ? [XMLNode(tag: "desc", text: description)] : []),
        ...(isRequired ? [XMLNode(tag: "required")] : []),
        ...(values.map((value) => XMLNode(tag: "value", text: value)).toList()),
        ...(options.map((option) => option.toXml()))
      ]
    );
  }
}

class DataForm {
  final String type;
  final String? title;
  final List<String> instructions;
  final List<DataFormField> fields;
  final List<DataFormField> reported;
  final List<List<DataFormField>> items;

  const DataForm({
      required this.type,
      required this.instructions,
      required this.fields,
      required this.reported,
      required this.items,
      this.title
  });

  DataFormField? getFieldByVar(String varAttr) {
    return firstWhereOrNull(fields, (field) => field.varAttr == varAttr);
  }
  
  XMLNode toXml() {
    return XMLNode.xmlns(
      tag: "x",
      xmlns: dataFormsXmlns,
      attributes: {
        "type": type
      },
      children: [
        ...(instructions.map((i) => XMLNode(tag: "instruction", text: i)).toList()),
        ...(title != null ? [XMLNode(tag: "title", text: title)] : []),
        ...(fields.map((field) => field.toXml()).toList()),
        ...(reported.map((report) => report.toXml()).toList()),
        ...(items.map((item) => XMLNode(
              tag: "item",
              children: item.map((i) => i.toXml()).toList()
          )).toList()),
      ]
    );
  }
}

DataFormOption _parseDataFormOption(XMLNode option) {
  return DataFormOption(
    label: option.attributes["label"],
    value: option.firstTag("value")!.innerText()
  );
}

DataFormField _parseDataFormField(XMLNode field) {
  final desc = field.firstTag("desc")?.innerText();
  final isRequired = field.firstTag("required") != null;
  final values = field.findTags("value").map((i) => i.innerText()).toList();
  final options = field.findTags("option").map((i) => _parseDataFormOption(i)).toList();

  return DataFormField(
    varAttr: field.attributes["var"],
    type: field.attributes["type"],
    options: options,
    values: values,
    isRequired: isRequired,
    description: desc
  );
}

/// Parse a Data Form declaration.
DataForm parseDataForm(XMLNode x) {
  assert(x.attributes["xmlns"] == dataFormsXmlns);
  assert(x.tag == "x");

  final type = x.attributes["type"]!;
  final title = x.firstTag("title")?.innerText();
  final instructions = x.findTags("instructions").map((i) => i.innerText()).toList();
  final fields = x.findTags("field").map((i) => _parseDataFormField(i)).toList();
  final reported = x.firstTag("reported")?.findTags("field").map((i) => _parseDataFormField(i.firstTag("field")!)).toList() ?? [];
  final items = x.findTags("item").map((i) => i.findTags("field").map((j) => _parseDataFormField(j)).toList()).toList();

  return DataForm(
    type: type,
    instructions: instructions,
    fields: fields,
    reported: reported,
    items: items,
    title: title
  );
}
