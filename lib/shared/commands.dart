import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/models/message.dart";

abstract class BaseIsolateCommand {
  Map<String, dynamic> toJson();
  //BaseIsolateEvent fromJson(Map<String, dynamic> json);
}

const performLoginType = "PerformLoginAction";
class PerformLoginAction extends BaseIsolateCommand {
  final String jid;
  final String password;
  final bool useDirectTLS;
  final bool allowPlainAuth;

  PerformLoginAction({ required this.jid, required this.password, required this.useDirectTLS, required this.allowPlainAuth });
  PerformLoginAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]!,
    password = json["password"]!,
    useDirectTLS = json["useDirectTLS"]!,
    allowPlainAuth = json["allowPlainAuth"]! {
      assert(json["type"] == performLoginType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": performLoginType,
    "jid": jid,
    "password": password,
    "useDirectTLS": useDirectTLS,
    "allowPlainAuth": allowPlainAuth
  };
}

const loadConversationsType = "LoadConversationsAction";
class LoadConversationsAction extends BaseIsolateCommand {
  @override
  Map<String, dynamic> toJson() => {
    "type": loadConversationsType
  };
}

const loadMessagesForJidActionType = "LoadMessagesForJidAction";
class LoadMessagesForJidAction extends BaseIsolateCommand {
  final String jid;

  LoadMessagesForJidAction({ required this.jid });
  LoadMessagesForJidAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]! {
      assert(json["type"] == loadMessagesForJidActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": loadMessagesForJidActionType,
    "jid": jid
  };
}

const setCurrentlyOpenChatType = "SetCurrentlyOpenChatAction";
class SetCurrentlyOpenChatAction extends BaseIsolateCommand {
  final String jid;

  SetCurrentlyOpenChatAction({ required this.jid });
  SetCurrentlyOpenChatAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]! {
      assert(json["type"] == setCurrentlyOpenChatType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": setCurrentlyOpenChatType,
    "jid": jid
  };
}

const addToRosterType = "AddToRosterAction";
class AddToRosterAction extends BaseIsolateCommand {
  final String jid;

  AddToRosterAction({ required this.jid });
  AddToRosterAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]! {
      assert(json["type"] == addToRosterType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": addToRosterType,
    "jid": jid
  };
}

const removeRosterItemActionType = "RemoveRosterItemAction";
class RemoveRosterItemAction extends BaseIsolateCommand {
  final String jid;

  RemoveRosterItemAction({ required this.jid });
  RemoveRosterItemAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]! {
      assert(json["type"] == removeRosterItemActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": removeRosterItemActionType,
    "jid": jid
  };
}

const addConversationActionType = "AddConversationAction";
class AddConversationAction extends BaseIsolateCommand {
  final String jid;
  final String title;
  final String avatarUrl;
  final String lastMessageBody;

  AddConversationAction({
      required this.jid,
      required this.title,
      required this.avatarUrl,
      required this.lastMessageBody
  });
  AddConversationAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]!,
    title = json["title"]!,
    avatarUrl = json["avatarUrl"]!,
    lastMessageBody = json["lastMessageBody"]! {
      assert(json["type"] == addToRosterType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": addConversationActionType,
    "jid": jid,
    "title": title,
    "avatarUrl": avatarUrl,
    "lastMessageBody": lastMessageBody
  };
}

const sendMessageActionType = "SendMessageAction";
class SendMessageAction extends BaseIsolateCommand {
  final String jid;
  final String body;
  final Message? quotedMessage;

  SendMessageAction({
      required this.jid,
      required this.body,
      this.quotedMessage
  });
  SendMessageAction.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]!,
    body = json["body"]!,
    quotedMessage = json.containsKey("quotedMessage") ? Message.fromJson(json["quotedMessage"]!) : null {
      assert(json["type"] == sendMessageActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": sendMessageActionType,
    "jid": jid,
    "body": body,
    ...(quotedMessage != null ? { "quotedMessage": quotedMessage!.toJson() } : {})
  };
}

const setCSIStateType = "SetCSIState";
class SetCSIStateAction extends BaseIsolateCommand {
  final String state;

  SetCSIStateAction({ required this.state });
  SetCSIStateAction.fromJson(Map<String, dynamic> json) :
    state = json["state"]! {
      assert(json["type"] == setCSIStateType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": setCSIStateType,
    "state": state
  };
}

const performPrestartActionType = "PerformPrestartAction";
class PerformPrestartAction extends BaseIsolateCommand {
  PerformPrestartAction();
  PerformPrestartAction.fromJson(Map<String, dynamic> json) {
      assert(json["type"] == performPrestartActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": performPrestartActionType
  };
}

const debugSetEnabledActionType = "DebugSetEnabledAction";
class DebugSetEnabledAction extends BaseIsolateCommand {
  final bool enabled;

  DebugSetEnabledAction({ required this.enabled });
  DebugSetEnabledAction.fromJson(Map<String, dynamic> json) :
    enabled = json["enabled"]! {
      assert(json["type"] == debugSetEnabledActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": debugSetEnabledActionType,
    "enabled": enabled
  };
}

const debugSetIpActionType = "DebugSetIpAction";
class DebugSetIpAction extends BaseIsolateCommand {
  final String ip;

  DebugSetIpAction({ required this.ip });
  DebugSetIpAction.fromJson(Map<String, dynamic> json) :
    ip = json["ip"]! {
      assert(json["type"] == debugSetIpActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": debugSetIpActionType,
    "ip": ip
  };
}

const debugSetPortActionType = "DebugSetPortAction";
class DebugSetPortAction extends BaseIsolateCommand {
  final int port;

  DebugSetPortAction({ required this.port });
  DebugSetPortAction.fromJson(Map<String, dynamic> json) :
    port = json["port"]! {
      assert(json["type"] == debugSetPortActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": debugSetPortActionType,
    "port": port
  };
}

const debugSetPassphraseActionType = "DebugSetPassphraseAction";
class DebugSetPassphraseAction extends BaseIsolateCommand {
  final String passphrase;

  DebugSetPassphraseAction({ required this.passphrase });
  DebugSetPassphraseAction.fromJson(Map<String, dynamic> json) :
    passphrase = json["passphrase"]! {
      assert(json["type"] == debugSetPassphraseActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": debugSetPassphraseActionType,
    "passphrase": passphrase
  };
}

const performDownloadActionType = "PerformDownloadAction";
class PerformDownloadAction extends BaseIsolateCommand {
  final Message message;

  PerformDownloadAction({ required this.message });
  PerformDownloadAction.fromJson(Map<String, dynamic> json) :
    message = Message.fromJson(json["message"]!) {
      assert(json["type"] == performDownloadActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": performDownloadActionType,
    "message": message.toJson(),
  };
}

const setPreferencesCommandType = "SetPreferencesCommand";
class SetPreferencesCommand extends BaseIsolateCommand {
  final PreferencesState preferences;

  SetPreferencesCommand({ required this.preferences });
  SetPreferencesCommand.fromJson(Map<String, dynamic> json) :
    preferences = PreferencesState.fromJson(json["preferences"]!) {
      assert(json["type"] == setPreferencesCommandType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": setPreferencesCommandType,
    "preferences": preferences.toJson(),
  };
}

const stopActionType = "__STOP__";
class StopAction extends BaseIsolateCommand {
  StopAction();
  StopAction.fromJson(Map<String, dynamic> json) {
      assert(json["type"] == stopActionType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": stopActionType
  };
}
