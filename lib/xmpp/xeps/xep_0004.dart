import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

class DataFormOption {

  const DataFormOption({ required this.value, this.label });
  final String? label;
  final String value;

  XMLNode toXml() {
    return XMLNode(
      tag: 'option',
      attributes: label != null ? <String, dynamic>{ 'label': label } : <String, dynamic>{},
      children: [
        XMLNode(
          tag: 'value',
          text: value,
        )
      ],
    );
  }
}

class DataFormField {

  const DataFormField({
      required this.options,
      required this.values,
      required this.isRequired,
      this.varAttr,
      this.type,
      this.description,
      this.label,
  });
  final String? description;
  final bool isRequired;
  final List<String> values;
  final List<DataFormOption> options;
  final String? type;
  final String? varAttr;
  final String? label;

  XMLNode toXml() {
    return XMLNode(
      tag: 'field',
      attributes: <String, dynamic>{
        ...varAttr != null ? <String, dynamic>{ 'var': varAttr } : <String, dynamic>{},
        ...type != null ? <String, dynamic>{ 'type': type } : <String, dynamic>{},
        ...label != null ? <String, dynamic>{ 'label': label } : <String, dynamic>{}
      },
      children: [
        ...description != null ? [XMLNode(tag: 'desc', text: description)] : [],
        ...isRequired ? [XMLNode(tag: 'required')] : [],
        ...values.map((value) => XMLNode(tag: 'value', text: value)).toList(),
        ...options.map((option) => option.toXml())
      ],
    );
  }
}

class DataForm {

  const DataForm({
      required this.type,
      required this.instructions,
      required this.fields,
      required this.reported,
      required this.items,
      this.title,
  });
  final String type;
  final String? title;
  final List<String> instructions;
  final List<DataFormField> fields;
  final List<DataFormField> reported;
  final List<List<DataFormField>> items;

  DataFormField? getFieldByVar(String varAttr) {
    return firstWhereOrNull(fields, (field) => field.varAttr == varAttr);
  }
  
  XMLNode toXml() {
    return XMLNode.xmlns(
      tag: 'x',
      xmlns: dataFormsXmlns,
      attributes: {
        'type': type
      },
      children: [
        ...instructions.map((i) => XMLNode(tag: 'instruction', text: i)).toList(),
        ...title != null ? [XMLNode(tag: 'title', text: title)] : [],
        ...fields.map((field) => field.toXml()).toList(),
        ...reported.map((report) => report.toXml()).toList(),
        ...items.map((item) => XMLNode(
              tag: 'item',
              children: item.map((i) => i.toXml()).toList(),
          ),).toList(),
      ],
    );
  }
}

DataFormOption _parseDataFormOption(XMLNode option) {
  return DataFormOption(
    label: option.attributes['label'] as String?,
    value: option.firstTag('value')!.innerText(),
  );
}

DataFormField _parseDataFormField(XMLNode field) {
  final desc = field.firstTag('desc')?.innerText();
  final isRequired = field.firstTag('required') != null;
  final values = field.findTags('value').map((i) => i.innerText()).toList();
  final options = field.findTags('option').map(_parseDataFormOption).toList();

  return DataFormField(
    varAttr: field.attributes['var'] as String?,
    type: field.attributes['type'] as String?,
    options: options,
    values: values,
    isRequired: isRequired,
    description: desc,
  );
}

/// Parse a Data Form declaration.
DataForm parseDataForm(XMLNode x) {
  assert(x.attributes['xmlns'] == dataFormsXmlns, 'Invalid element xmlns');
  assert(x.tag == 'x', 'Invalid element name');

  final type = x.attributes['type']! as String;
  final title = x.firstTag('title')?.innerText();
  final instructions = x.findTags('instructions').map((i) => i.innerText()).toList();
  final fields = x.findTags('field').map(_parseDataFormField).toList();
  final reported = x.firstTag('reported')?.findTags('field').map((i) => _parseDataFormField(i.firstTag('field')!)).toList() ?? [];
  final items = x.findTags('item').map((i) => i.findTags('field').map(_parseDataFormField).toList()).toList();

  return DataForm(
    type: type,
    instructions: instructions,
    fields: fields,
    reported: reported,
    items: items,
    title: title,
  );
}
