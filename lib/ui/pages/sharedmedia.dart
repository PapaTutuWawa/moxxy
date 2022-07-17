import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/sharedmedia_bloc.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class SharedMediaPage extends StatelessWidget {
  const SharedMediaPage({ Key? key }) : super(key: key);

  // ignore: implicit_dynamic_type
  static MaterialPageRoute get route => MaterialPageRoute(builder: (_) => const SharedMediaPage());
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedMediaBloc, SharedMediaState>(
      builder: (BuildContext context, SharedMediaState state) {
        return Scaffold(
          appBar: BorderlessTopbar.simple(state.title),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: [
                // TODO(Unknown): This is really unoptimized
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: state.sharedMedia.reversed.map((medium) {
                      return buildSharedMediaWidget(medium, state.jid);
                  }).toList(),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
