import "dart:async";
import "dart:convert";

import "package:moxxyv2/redux/account/state.dart";

import "package:flutter_secure_storage/flutter_secure_storage.dart";

// TODO: Move into XmppRepository

Future<void> secureDebugPrint(FlutterSecureStorage storage) async {
  final data = await storage.readAll();
  // TODO: Use a logging function
  // ignore: avoid_print
  print(data.toString());
}

Future<AccountState?> getAccountData() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );

  if (await storage.containsKey(key: "account")) {
    final accountStr = await storage.read(key: "account");

    if (accountStr != null) {
      return AccountState.fromJson(jsonDecode(accountStr));
    } else {
      await secureDebugPrint(storage);
      return null;
    }
  } else {
    await secureDebugPrint(storage);
    return null;
  }
}

Future<void> setAccountData(AccountState state) async {
  // TODO: This sometimes fails
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );

  await storage.write(
    key: "account",
    value: jsonEncode(state.toJson())
  );
}

Future<void> removeAccountData() async {
  // TODO: This sometimes fails
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );

  await storage.delete(key: "account");
}
