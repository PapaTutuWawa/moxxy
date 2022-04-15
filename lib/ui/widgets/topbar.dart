import "package:flutter/material.dart";

class TopbarTitleText extends StatelessWidget {
  final String text;

  const TopbarTitleText(this.text, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20
      )
    );
  }
}

class TopbarAvatarAndName extends StatelessWidget {
  final Widget title;
  final Widget avatar;
  final List<Widget> extra;
  final bool showBackButton;
  final void Function() onTap;

  const TopbarAvatarAndName(this.title, this.avatar, this.onTap, { this.showBackButton = true, this.extra = const [], Key? key }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Visibility(
          child: const BackButton(),
          visible: showBackButton
        ),
        Center(
          child: InkWell(
            child: Row(
              children: [
                avatar,
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: title
                )
              ]
            ),
            onTap: onTap
          )
        ),
        const Spacer(),
        ...extra
      ]
    );
  }
}

/// Provides a Signal-like topbar without borders or anything else
class BorderlessTopbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget child;

  const BorderlessTopbar(this.child, { Key? key }) : super(key: key);

  BorderlessTopbar.justBackButton({ Key? key })
    : this(Row(children: const [ BackButton() ]), key: key);
  
  /// A simple borderless topbar that displays just the back button (if wanted) and a
  /// Text() title.
  BorderlessTopbar.simple(String title, { List<Widget> extra = const [], bool showBackButton = true, Key? key }) : this(Row(
      children: [
        Visibility(
          child: const BackButton(),
          visible: showBackButton
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20
          )
        ),
        ...extra
      ]
  ), key: key);
  
  /// Displays a clickable avatar and title and a back button, if wanted
  const BorderlessTopbar.avatarAndName(TopbarAvatarAndName child, { Key? key }) : this(child, key: key);
  
  @override
  final Size preferredSize = const Size.fromHeight(60);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child
        )
      )
    );
  }
}
