import 'package:flutter/material.dart';

class TopbarTitleText extends StatelessWidget {
  const TopbarTitleText(this.text, { Key? key }) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
      ),
    );
  }
}

class TopbarAvatarAndName extends StatelessWidget {
  const TopbarAvatarAndName(
    this.title,
    this.avatar,
    this.onTap,
    {
      this.showBackButton = true,
      this.extra = const [],
      Key? key,
    }
  ) : super(key: key);
  final Widget title;
  final Widget avatar;
  final List<Widget> extra;
  final bool showBackButton;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Visibility(
          visible: showBackButton,
          child: const BackButton(),
        ),
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              avatar,
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: title,
              ),
            ],
          ),
        ),
        const Spacer(),
        ...extra,
      ],
    );
  }
}

/// Provides a Signal-like topbar without borders or anything else
class BorderlessTopbar extends StatelessWidget implements PreferredSizeWidget {

  const BorderlessTopbar(this.child, { Key? key })
    : preferredSize = const Size.fromHeight(60),
      super(key: key);

  factory BorderlessTopbar.justBackButton({ Key? key }) {
    return BorderlessTopbar(
      Row(children: const [ BackButton() ]),
      key: key,
    );
  }

  /// A simple borderless topbar that displays just the back button (if wanted) and a
  /// Text() title.
  factory BorderlessTopbar.simple(String title, { List<Widget> extra = const [], bool showBackButton = true, Key? key }) {
    return BorderlessTopbar(
      Row(
        children: [
          Visibility(
            visible: showBackButton,
            child: const BackButton(),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          ...extra,
        ],
      ),
      key: key,
    );
  }

  /// Displays a clickable avatar and title and a back button, if wanted
  factory BorderlessTopbar.avatarAndName(TopbarAvatarAndName child, { Key? key }) {
    return BorderlessTopbar(child, key: key);
  }

  final Widget child;

  @override
  final Size preferredSize;
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
