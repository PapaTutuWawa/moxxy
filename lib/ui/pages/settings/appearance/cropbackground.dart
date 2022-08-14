import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/button.dart';

class CropBackgroundPage extends StatefulWidget {

  const CropBackgroundPage({ Key? key }) : super(key: key);
  
  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const CropBackgroundPage(),
    settings: const RouteSettings(
      name: backgroundCroppingRoute,
    ),
  );

  @override
  CropBackgroundPageState createState() => CropBackgroundPageState();
}

class CropBackgroundPageState extends State<CropBackgroundPage> {

  CropBackgroundPageState() : _x = 0, _y = 0, _track = false, super();
  double _x = 0;
  double _y = 0;
  bool _track = false;

  double _scalingFactor(BuildContext context, CropBackgroundState state) {
    final size = MediaQuery.of(context).size;

    final q = size.height / state.imageHeight;
    final delta = size.width - state.imageWidth * q;
    if (delta > 0) {
      return size.width / state.imageWidth;
    } else {
      return q;
    }
  }

  
  Widget _buildImage(BuildContext context, CropBackgroundState state) {
    if (state.image == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final q = _scalingFactor(context, state);
    if (state.blurEnabled) {
      return Positioned(
        top: _y,
        left: _x,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Image.memory(
            state.image!,
            width: state.imageWidth * q,
            height: state.imageHeight * q,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      return Positioned(
        top: _y,
        left: _x,
        child: Image.memory(
          state.image!,
          width: state.imageWidth * q,
          height: state.imageHeight * q,
          fit: BoxFit.contain,
        ),
      );
    }
  }

  Widget _buildLoadingSpinner(CropBackgroundState state) {
    if (state.isWorking) {
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backdropBlack,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return const SizedBox();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CropBackgroundBloc, CropBackgroundState>(
      builder: (BuildContext context, CropBackgroundState state) => WillPopScope(
        onWillPop: () async {
          if (state.isWorking) return false;

          context.read<CropBackgroundBloc>().add(CropBackgroundResetEvent());
          return true;
        },
        child: SafeArea(
          child: GestureDetector(
            onPanDown: (_) => _track = true,
            onPanStart: (_) => _track = true,
            onPanEnd: (_) => _track = false,
            onPanCancel: () => _track = false,
            onPanUpdate: (event) {
              if (!_track) return;

              final query = MediaQuery.of(context);
              final q = _scalingFactor(context, state);
              setState(() {
                _x = min(
                  max(
                    _x + event.delta.dx,
                    query.size.width - state.imageWidth * q,
                  ),
                  0,
                );
                _y = min(
                  max(
                    _y + event.delta.dy,
                    query.size.height - state.imageHeight * q,
                  ),
                  0,
                );
              });
            },
            child: Stack(
              children: [
                _buildImage(context, state),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: const Color.fromRGBO(0, 0, 0, 0),
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                      onPressed: () => context.read<NavigationBloc>().add(PoppedRouteEvent()),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: const Color.fromRGBO(0, 0, 0, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IntrinsicWidth(
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text('Blur background'),
                            ),
                            Switch(
                              value: state.blurEnabled,
                              onChanged: (_) {
                                if (state.isWorking) return;
                                
                                context.read<CropBackgroundBloc>()
                                  .add(BlurToggledEvent());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RoundedButton(
                        color: primaryColor,
                        cornerRadius: 100,
                        onTap: () {
                          if (state.isWorking) return;

                          context.read<CropBackgroundBloc>().add(
                            BackgroundSetEvent(
                              _x,
                              _y,
                              _scalingFactor(context, state),
                              MediaQuery.of(context).size.height,
                              MediaQuery.of(context).size.width,
                            ),
                          );
                        },
                        child: const Text('Set as background image'),
                      ),
                    ],
                  ),
                ),
                _buildLoadingSpinner(state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
