// TODO: Handle the underscroll color change
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversations.dart';
import 'package:moxxyv2/ui/helpers.dart';

class ConversationsHomeAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const ConversationsHomeAppBar({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.title,
    required this.actions,
    required this.controller,
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

  /// The controller for the search TextField.
  final TextEditingController controller;

  @override
  Size get preferredSize => Size.fromHeight(
        pxToLp(168),
      );

  @override
  ConversationsHomeAppBarState createState() => ConversationsHomeAppBarState();
}

class ConversationsHomeAppBarState extends State<ConversationsHomeAppBar> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onTextFieldChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextFieldChanged);

    super.dispose();
  }

  void _onTextFieldChanged() {
    GetIt.I.get<ConversationsCubit>().setSearchText(widget.controller.text);
  }

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
                        onPressed: () {
                          // Reset the search text.
                          widget.controller.text = '';

                          // Close the search and reset the search.
                          context.read<ConversationsCubit>()
                            ..setSearchOpen(false)
                            ..resetSearchResults()
                            ..setSearchText('');
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: pxToLp(24)),
                          child: SizedBox(
                            height: pxToLp(104),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Material(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: pxToLp(48),
                                  ),
                                  // TODO: The text is not centered
                                  child: TextField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      // TODO: i18n
                                      hintText: 'Search...',
                                      contentPadding: EdgeInsets.zero,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          state.searchText.isNotEmpty
                                              ? Icons.close
                                              : Icons.search,
                                          size: pxToLp(72),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        onPressed: () {
                                          final cubit = context
                                              .read<ConversationsCubit>();
                                          if (state.searchText.isNotEmpty) {
                                            widget.controller.text = '';
                                            cubit
                                              ..setSearchText('')
                                              // Reset the search results
                                              ..resetSearchResults();
                                          }
                                        },
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                      fontSize: ptToFontSize(32),
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: widget.controller,
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
