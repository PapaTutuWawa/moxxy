enum ParserState {
  variableName,
  variableValue
}

/// Parse a string like "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL" into
/// { "n": "user", "r": "fyko+d2lbbFgONRv9qkxdawL"}.
Map<String, String> parseKeyValue(String keyValueString) {
  ParserState state = ParserState.variableName;
  String name = "";
  String value = "";
  Map<String, String> values = {};

  for (int i = 0; i < keyValueString.length; i++) {
    final char = keyValueString[i];
    switch (state) {
      case ParserState.variableName: {
        if (char == "=") {
          state = ParserState.variableValue; 
        } else if (char == ",") {
          name = "";
        } else {
          name += char;
        }
      }
      break;
      case ParserState.variableValue: {
        if (char == "," || i == keyValueString.length - 1) {
          if (char != ",") {
            value += char;
          }

          values[name] = value;
          value = "";
          name = "";
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
