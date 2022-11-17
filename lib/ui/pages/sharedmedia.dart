import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/ui/bloc/sharedmedia_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class SharedMediaPage extends StatelessWidget {
  const SharedMediaPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const SharedMediaPage(),
    settings: const RouteSettings(
      name: sharedMediaRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedMediaBloc, SharedMediaState>(
      builder: (BuildContext context, SharedMediaState state) {
        // TODO(Unknown): This can most likely be optimised. Maybe begin with storing the
        //                shared media already in this format so we don't have to do that
        //                while drawing the UI.
        final numElements = (MediaQuery.of(context).size.width - 16) /~ 75;

        final rows = List<List<SharedMedium>>.empty(growable: true);
        var currentRow = List<SharedMedium>.empty(growable: true);
        for (var i = state.sharedMedia.length - 1; i >= 0; i--) {
          final item = state.sharedMedia[i];
          final thisMediaDateTime = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
          final lastMediaDateTime = i < state.sharedMedia.length - 1 ?
            DateTime.fromMillisecondsSinceEpoch(state.sharedMedia[i + 1].timestamp) :
            null;

          final newDay = lastMediaDateTime != null && (
            lastMediaDateTime.day != thisMediaDateTime.day ||
            lastMediaDateTime.month != thisMediaDateTime.month ||
            lastMediaDateTime.year != thisMediaDateTime.year
          );
            
          if (currentRow.length == numElements || newDay) {
            rows.add(currentRow);
            currentRow = List<SharedMedium>.empty(growable: true);
          }

          currentRow.add(item);
        }

        if (currentRow.isNotEmpty) {
          rows.add(currentRow);
        }

        final now = DateTime.now();
        return Scaffold(
          appBar: BorderlessTopbar.simple(state.title),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              itemBuilder: (context, index) {
                final row = rows[index];
                final firstDateTime = DateTime.fromMillisecondsSinceEpoch(row.first.timestamp);
                return Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            formatDateBubble(firstDateTime, now),
                            style: const TextStyle(
                              fontSize: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: row.map((medium) {
                            return buildSharedMediaWidget(medium, state.jid);
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
              itemCount: rows.length,
            ),
          ),
        );
      },
    );
  }
}
