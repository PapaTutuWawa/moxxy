class AccountState {
  final String jid;
  final String displayName;
  final String avatarUrl;
  final String streamResumptionToken;

  const AccountState({ required this.jid, required this.displayName, required this.avatarUrl, this.streamResumptionToken = "" });
  const AccountState.initialState() : jid = "", avatarUrl = "", displayName = "", streamResumptionToken = "";
  
  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      jid: json["jid"],
      displayName: json["displayName"],
      avatarUrl: json["avatarUrl"],
      streamResumptionToken: json["streamResumptionToken"]
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "jid": jid,
      "displayName": displayName,
      "avatarUrl": avatarUrl,
      "streamResumptionToken": streamResumptionToken
    };
  }
  
  AccountState copyWith({ String? jid, String? displayName, String? avatarUrl }) {
    return AccountState(
      jid: jid ?? this.jid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
