/// Conversion helpers for bool <-> int as sqlite has no "real" booleans
int boolToInt(bool b) => b ? 1 : 0;
bool intToBool(int i) => i == 0 ? false : true;

String boolToString(bool b) => b ? 'true' : 'false';
bool stringToBool(String s) => s == 'true' ? true : false;

String intToString(int i) => '$i';
int stringToInt(String s) => int.parse(s);
