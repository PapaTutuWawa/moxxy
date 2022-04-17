class JID {
  String _local;
  String _domain;
  String _resource;

  JID(this._local, this._domain, this._resource);

  JID.fromString(String jid): _local = "", _domain = "", _resource = "" {
    // 0: Parsing either the local or domain part
    // 1: Parsing the domain part
    // 2: Parsing the resource
    int state = 0;
    String buffer = "";
    
    for (int i = 0; i < jid.length; i++) {
      final c = jid[i];
      final eol = i == jid.length - 1;
      
      switch (state) {
        case 0: {
          if (c == "@") {
            _local = buffer;
            buffer = "";
            state = 1;
          } else if (c == "/") {
            _domain = buffer;
            buffer = "";
            state = 2;
          } else if (eol) {
            _domain = buffer + c;
          } else {
            buffer += c;
          }
        }
        break;
        case 1: {
          if (c == "/") {
            _domain = buffer;
            buffer = "";
            state = 2;
          } else if (eol) {
            _domain = buffer;

            if (c != " ") {
              _domain = _domain + c;
            }
          } else if (c != " ") {
            buffer += c;
          }
        }
        break;
        case 2: {
          if (eol) {
            _resource = buffer;

            if (c != " ") {
              _resource = _resource + c;
            }
          } else if (c != ""){
            buffer += c;
          }
        }
      }
    }
  }

  String get local => _local;
  String get domain => _domain;
  String get resource => _resource;

  bool isBare() => resource.isEmpty;
  bool isFull() => resource.isNotEmpty;

  JID toBare() => JID(_local, _domain, "");
  JID withResource(String resource) => JID(_local, _domain, resource);
  
  @override
  String toString() {
    String result = "";

    if (local.isNotEmpty) {
      result += "$local@$domain";
    } else {
      result += domain;
    }
    if (isFull()) {
      result += "/$resource";
    }

    return result;
  }

  @override
  // ignore: hash_and_equals
  // NOTE: I really don't want to implement my own hashCode. Just let [Object] do its
  //       magic
  bool operator ==(Object other) {
    if (other is JID) {
      return other.local == _local && other.domain == _domain && other.resource == _resource;
    }

    return false;
  }
}
