enum ParserState {
  variableName,
  variableValue
}

/// Parse a string like "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL" into
/// { "n": "user", "r": "fyko+d2lbbFgONRv9qkxdawL"}.
Map<String, String> parseKeyValue(String keyValueString) {
  var state = ParserState.variableName;
  var name = '';
  var value = '';
  final values = <String, String>{};

  for (var i = 0; i < keyValueString.length; i++) {
    final char = keyValueString[i];
    switch (state) {
      case ParserState.variableName: {
        if (char == '=') {
          state = ParserState.variableValue; 
        } else if (char == ',') {
          name = '';
        } else {
          name += char;
        }
      }
      break;
      case ParserState.variableValue: {
        if (char == ',' || i == keyValueString.length - 1) {
          if (char != ',') {
            value += char;
          }

          values[name] = value;
          value = '';
          name = '';
          state = ParserState.variableName;
        } else {
          value += char;
        }
      }
      break;
    }
  }

  return values;
}
