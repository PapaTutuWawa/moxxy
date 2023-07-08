import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BartChartItem {
  const BartChartItem(
    this.name,
    this.value,
    this.color,
  );

  /// The title of the bar.
  final String name;

  /// The absolute value of the bar.
  final int value;

  /// The color of the bar.
  final Color color;
}

/// A bar chart that displays all individual bars next to each other inside a singular
/// line.
class StackedBarChart extends StatelessWidget {
  const StackedBarChart({
    required this.width,
    required this.items,
    this.height = 15,
    this.showPlaceholderBars = false,
    super.key,
  });

  /// The width of the widget.
  final double width;

  /// The height of the bar chart.
  final double height;

  /// The lines to display.
  final List<BartChartItem> items;

  /// Whether to just show a gray bar until values have been loaded.
  final bool showPlaceholderBars;

  @override
  Widget build(BuildContext context) {
    var rightOffset = 0.0;
    final total = items
        .map((item) => item.value)
        .reduce((value, element) => value + element);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: showPlaceholderBars
                  ? [
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: ColoredBox(
                          color: Colors.grey,
                        ),
                      ),
                    ]
                  : items.reversed.map(
                      (item) {
                        // We reverse the item list and use the offset from the right
                        // border so that we can have a nice stacking effect.
                        final ro = rightOffset;
                        final itemWidth = width * (item.value / total) + height;
                        rightOffset += itemWidth;
                        return Positioned(
                          // Clamp the offset from the right border to [0, inf)
                          right: max(
                            ro - height,
                            0,
                          ),
                          top: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(height),
                              bottomRight: Radius.circular(height),
                            ),
                            child: SizedBox(
                              width: itemWidth,
                              height: height,
                              child: ColoredBox(
                                color: item.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map(
                  (item) => [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(height),
                      child: SizedBox(
                        width: height,
                        height: height,
                        child: ColoredBox(
                          color: item.color,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(item.name),
                    ),
                  ],
                )
                .flattened
                .toList(),
          ),
        ),
      ],
    );
  }
}
