import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

@freezed
class Account with _$Account {
  factory Account({
    // The displayname to use.
    @Default('') String displayName,

    // The path to the account's profile picture.
    String? avatarPath,

    // The hash of our own avatar.
    String? avatarHash,

    // The account's JID.
    @Default('') String jid,
  }) = _Account;
}

@freezed
class AccountState with _$AccountState {
  factory AccountState({
    @Default([]) List<Account> accounts,
    @Default(-1) int currentAccount,
  }) = _AccountState;

  const AccountState._();

  Account get account {
    assert(currentAccount != -1, 'currentAccount must be != -1');
    return accounts[currentAccount];
  }
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(AccountState());

  /// Sets the account list to [accounts].
  void setAccounts(List<Account> accounts, int current) {
    emit(
      state.copyWith(
        accounts: accounts,
        currentAccount: current,
      ),
    );
  }

  /// Update the account's avatar data in the UI.
  void changeAvatar(String path, String hash) {
    final newList = List<Account>.from(state.accounts)
      ..removeAt(state.currentAccount)
      ..insert(
        state.currentAccount,
        state.account.copyWith(
          avatarPath: path,
          avatarHash: hash,
        ),
      );
    emit(
      state.copyWith(
        accounts: newList,
      ),
    );
  }
}
