import 'package:bloc/bloc.dart';
import 'package:moxxyv2/ui/bloc/state/account.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(AccountState());

  /// The the current account to [account].
  void setAccount(AccountState account) {
    emit(account);
  }

  /// Update the account's avatar data in the UI.
  void changeAvatar(String path, String hash) {
    emit(
      state.copyWith(
        avatarPath: path,
        avatarHash: hash,
      ),
    );
  }
}
