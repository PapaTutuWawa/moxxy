import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';

const double _accountListTileVerticalPadding = 8;
const double _accountListTilePictureHeight = 58;

class AccountListTile extends StatelessWidget {
  const AccountListTile({
    required this.displayName,
    required this.jid,
    required this.active,
    super.key,
  });

  /// The display name of the account
  final String displayName;

  /// The JID of the account.
  final String jid;

  /// Flag indicating whether the account is currently active.
  final bool active;

  static double get height =>
      _accountListTileVerticalPadding * 2 + _accountListTilePictureHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      // TODO: OnTap
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: _accountListTileVerticalPadding,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                active ? Icons.radio_button_on : Icons.radio_button_off,
                size: 20,
                color: active ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              // TODO: Pass the JID of our different account here.
              child: SquircleCachingXMPPAvatar.self(
                size: _accountListTilePictureHeight,
                borderRadius: 12,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    jid,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 30,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountsBottomModal extends StatelessWidget {
  const AccountsBottomModal({
    required this.extent,
    required this.tiles,
    super.key,
  });

  /// The extent of the bottom modal.
  final double extent;

  final List<AccountListTile> tiles;

  static void show(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cubit = context.read<AccountCubit>();
    final accounts = cubit.state.accounts;
    final extent = clampDouble(
      // TODO: Update to 3.16 and use mq.textScaler.scale(20) to get the logical size?
      (accounts.length * AccountListTile.height + 80) / mq.size.height,
      0,
      0.9,
    );

    final tiles = accounts
        .map(
          (account) => AccountListTile(
            displayName: account.displayName,
            jid: account.jid,
            active: account.jid == cubit.state.account.jid,
          ),
        )
        .toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => AccountsBottomModal(extent: extent, tiles: tiles),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        return DraggableScrollableSheet(
          expand: false,
          snap: true,
          minChildSize: extent,
          initialChildSize: extent,
          maxChildSize: extent,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            // Disable scrolling when we don't "fill" the screen.
            physics: extent < 0.9 ? const NeverScrollableScrollPhysics() : null,
            children: [
              ...tiles,
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          // TODO: i18n
                          'Add another account',
                          style: TextStyle(
                            fontSize: 20,
                            height: 2,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inverseSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
