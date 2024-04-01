// TODO: Handle the underscroll color change
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/state/conversations.dart';
import 'package:moxxyv2/ui/helpers.dart';

/// A wrapper around IconButton where the icon is controlled by whether
/// the [TextField] has text in it or not.
class SearchFieldIconButton extends StatefulWidget {
  const SearchFieldIconButton({super.key});

  @override
  SearchFieldIconButtonState createState() => SearchFieldIconButtonState();
}

class SearchFieldIconButtonState extends State<SearchFieldIconButton> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    final controller = GetIt.I.get<ConversationsCubit>().searchBarController;
    _hasText = controller.text.isNotEmpty;
    controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    GetIt.I
        .get<ConversationsCubit>()
        .searchBarController
        .removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText =
        GetIt.I.get<ConversationsCubit>().searchBarController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _hasText ? Icons.close : Icons.search,
        size: pxToLp(72),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: () {
        final cubit = context.read<ConversationsCubit>();
        if (_hasText) {
          cubit.resetSearchText();
        }
      },
    );
  }
}

class ConversationsHomeAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const ConversationsHomeAppBar({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.title,
    required this.actions,
    super.key,
  });

  /// The color of icons on the AppBar.
  final Color foregroundColor;

  /// The color of the AppBar itself.
  final Color backgroundColor;

  /// The title widget.
  final Widget title;

  /// The actions that are outside of the search.
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(
        pxToLp(168),
      );

  @override
  ConversationsHomeAppBarState createState() => ConversationsHomeAppBarState();
}

class ConversationsHomeAppBarState extends State<ConversationsHomeAppBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: widget.preferredSize.height,
        child: Material(
          color: widget.backgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pxToLp(48)),
            child: IconTheme(
              data: Theme.of(context).iconTheme.copyWith(
                    color: widget.foregroundColor,
                  ),
              child: BlocBuilder<ConversationsCubit, ConversationsState>(
                builder: (context, state) => AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: state.searchOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Row(
                    children: [
                      // NOTE: Ensures that the row is as tall as the second child
                      SizedBox(height: widget.preferredSize.height),

                      Expanded(child: widget.title),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          size: pxToLp(72),
                        ),
                        onPressed: () {
                          // Open the search.
                          context
                              .read<ConversationsCubit>()
                              .setSearchOpen(true);
                        },
                      ),
                      ...widget.actions,
                    ],
                  ),
                  secondChild: Row(
                    children: [
                      // NOTE: Ensures that the row is as tall as the second child
                      SizedBox(height: widget.preferredSize.height),

                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: pxToLp(72),
                        ),
                        onPressed:
                            context.read<ConversationsCubit>().closeSearchBar,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: pxToLp(24)),
                          child: SizedBox(
                            height: pxToLp(104),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(pxToLp(52)),
                              child: Material(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                child: Align(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: pxToLp(42),
                                      ),
                                      isDense: true,
                                      // TODO: i18n
                                      hintText: 'Search...',
                                      suffixIcon: const SearchFieldIconButton(),
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                      fontSize: ptToFontSize(32),
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: context
                                        .read<ConversationsCubit>()
                                        .searchBarController,
                                    onSubmitted: context
                                        .read<ConversationsCubit>()
                                        .performSearch,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
