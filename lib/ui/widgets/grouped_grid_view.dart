import 'package:flutter/material.dart';

/// A grouped list similar to that by the "grouped_list" package, but instead
/// rendering sublists, we render the actual list items in a grid.
/// T is the type of items the list should display, while K is the type
/// of the key that is used to group elements together.
class GroupedGridView<T, K> extends StatelessWidget {
  GroupedGridView({
    required List<T> elements,
    required this.getKey,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.gridPadding,
    this.controller,
    super.key,
  }) {
    if (elements.isEmpty) return;

    K? currentKey;
    for (var i = 0; i < elements.length; i++) {
      final key = getKey(elements[i]);

      if (currentKey == null || key != currentKey) {
        currentKey = key;
        _categories.add(
          List<T>.from([elements[i]]),
        );
      } else {
        _categories.last.add(elements[i]);
      }
    }
  }

  /// A list of items that are grouped together
  final List<List<T>> _categories = List<List<T>>.empty(growable: true);

  /// A builder function.
  final Widget Function(BuildContext, T) itemBuilder;

  /// The builder for the specified key.
  final Widget Function(BuildContext, K) separatorBuilder;

  /// Extracts the key from an item.
  final K Function(T) getKey;

  /// The SliverGridDelegate that is passed to each GridView.
  final SliverGridDelegate gridDelegate;

  /// Optional padding around each GridView.
  final EdgeInsets? gridPadding;

  /// Optional ScrollController that is attached to the ListView.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _categories.length * 2,
      controller: controller,
      itemBuilder: (context, index) {
        if (index.isEven) {
          return separatorBuilder(
            context,
            getKey(_categories[index ~/ 2].first),
          );
        } else {
          return Padding(
            padding: gridPadding ?? EdgeInsets.zero,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) => itemBuilder(
                context,
                _categories[(index - 1) ~/ 2][i],
              ),
              gridDelegate: gridDelegate,
              itemCount: _categories[(index - 1) ~/ 2].length,
            ),
          );
        }
      },
    );
  }
}
