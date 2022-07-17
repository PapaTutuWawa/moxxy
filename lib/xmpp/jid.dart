import 'package:meta/meta.dart';

@immutable
class JID {

  const JID(this.local, this.domain, this.resource);

  factory JID.fromString(String jid) {
    // 0: Parsing either the local or domain part
    // 1: Parsing the domain part
    // 2: Parsing the resource
    var state = 0;
    var buffer = '';
    var local_ = '';
    var domain_ = '';
    var resource_ = '';
    
    for (var i = 0; i < jid.length; i++) {
      final c = jid[i];
      final eol = i == jid.length - 1;
      
      switch (state) {
        case 0: {
          if (c == '@') {
            local_ = buffer;
            buffer = '';
            state = 1;
          } else if (c == '/') {
            domain_ = buffer;
            buffer = '';
            state = 2;
          } else if (eol) {
            domain_ = buffer + c;
          } else {
            buffer += c;
          }
        }
        break;
        case 1: {
          if (c == '/') {
            domain_ = buffer;
            buffer = '';
            state = 2;
          } else if (eol) {
            domain_ = buffer;

            if (c != ' ') {
              domain_ = domain_ + c;
            }
          } else if (c != ' ') {
            buffer += c;
          }
        }
        break;
        case 2: {
          if (eol) {
            resource_ = buffer;

            if (c != ' ') {
              resource_ = resource_ + c;
            }
          } else if (c != ''){
            buffer += c;
          }
        }
      }
    }

    return JID(local_, domain_, resource_);
  }
  final String local;
  final String domain;
  final String resource;

  bool isBare() => resource.isEmpty;
  bool isFull() => resource.isNotEmpty;

  JID toBare() => JID(local, domain, '');
  JID withResource(String resource) => JID(local, domain, resource);
  
  @override
  String toString() {
    var result = '';

    if (local.isNotEmpty) {
      result += '$local@$domain';
    } else {
      result += domain;
    }
    if (isFull()) {
      result += '/$resource';
    }

    return result;
  }

  @override
  // ignore: hash_and_equals
  // NOTE: I really don't want to implement my own hashCode. Just let [Object] do its
  //       magic
  bool operator ==(Object other) {
    if (other is JID) {
      return other.local == local && other.domain == domain && other.resource == resource;
    }

    return false;
  }

  /// I have no idea if that is correct.
  @override
  int get hashCode => local.hashCode + domain.hashCode + resource.hashCode;
}
