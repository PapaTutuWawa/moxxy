import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/keys_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class KeysPage extends StatelessWidget {
  const KeysPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const KeysPage(),
    settings: const RouteSettings(
      name: keysRoute,
    ),
  );

  Widget _buildBody(KeysState state) {
    if (state.working) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: state.keys.length,
      itemBuilder: (context, index) {
        var item = state.keys[index].fingerprint;

        final parts = List<String>.empty(growable: true);
        for (var i = 0; i < 8; i++) {
          final part = item.substring(0, 8);
          item = item.substring(8);
          parts.add(part);
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(textfieldRadiusRegular),
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    children: parts
                    .map((part_) => Text(
                      part_,
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 18,
                      ),
                    )).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Switch(
                        value: true,
                        onChanged: (_) {},
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          print('lol');
                        }
                      ),
                    ],
                  ),
                ],
              ),
            ),
            /*child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Wrap(
                  spacing: 6,
                  children: parts
                  .map((part_) => Text(
                      part_,
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 16,
                      ),
                  )).toList(),
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  top: 2,
                  bottom: 2,
                ),
                child: Text('OMEMO'),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  child: Icon(Icons.qr_code_scanner),
                  onTap: () {
                    print('lol');
                  }
                ),
              ),
            ),*/
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeysBloc, KeysState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple('Keys'),
        body: _buildBody(state),
      ),
    );
  }
}
