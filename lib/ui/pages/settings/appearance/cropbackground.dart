import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/button.dart';
import 'package:moxxyv2/ui/widgets/cancel_button.dart';

class CropBackgroundPage extends StatefulWidget {
  const CropBackgroundPage({ super.key });
  
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
  CropBackgroundPageState() : super();
  double? _scalingFactorCached;
  TransformationController? _controller;
  
  double _scalingFactor(BuildContext context, CropBackgroundState state) {
    if (_scalingFactorCached != null) return _scalingFactorCached!;

    final query = MediaQuery.of(context);
    final width = query.size.width;// * query.devicePixelRatio;
    final height = query.size.height;// * query.devicePixelRatio;

    final q = height / state.imageHeight;
    final delta = width - state.imageWidth * q;
    var qp = q;
    if (delta > 0) {
      qp = width / state.imageWidth;
    }

    _scalingFactorCached = qp;
    return qp;
  }
  
  Widget _buildImage(BuildContext context, CropBackgroundState state) {
    if (state.image == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    Widget image;
    if (state.blurEnabled) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Image.memory(
          state.image!,
          fit: BoxFit.contain,
        ),
      );
    } else {
      image = Image.memory(
        state.image!,
        fit: BoxFit.contain,
      );
    }
    
    final q = _scalingFactor(context, state);
    _controller ??= TransformationController(Matrix4.identity()..scale(q, q, 1));
    return InteractiveViewer(
      constrained: false,
      maxScale: 4,
      minScale: 1,
      panEnabled: !state.isWorking,
      scaleEnabled: !state.isWorking,
      transformationController: _controller,
      child: image,
    );
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
      builder: (BuildContext context, CropBackgroundState state) {
        return WillPopScope(
          onWillPop: () async {
            if (state.isWorking) return false;

            context.read<CropBackgroundBloc>().add(CropBackgroundResetEvent());
            return true;
          },
          child: SafeArea(
            child: Stack(
              children: [
                // ignore: prefer_if_elements_to_conditional_expressions
                state.imageHeight != 0 && state.imageWidth != 0 ?
                  _buildImage(context, state) :
                  const SizedBox(),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: const Color.fromRGBO(0, 0, 0, 0),
                    child: CancelButton(
                      onPressed: () {
                        context.read<CropBackgroundBloc>().add(CropBackgroundResetEvent());
                        context.read<NavigationBloc>().add(PoppedRouteEvent());
                      },
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
                        cornerRadius: 100,
                        onTap: () {
                          final q = _scalingFactor(context, state);
                          final value = _controller == null ?
                            (Matrix4.identity()..scale(q, q, 1)) :
                            _controller!.value;
                          final translation = value.getTranslation();
                          final scale = _controller == null ?
                            1.0 :
                            value.entry(0, 0);

                          context.read<CropBackgroundBloc>().add(
                            BackgroundSetEvent(
                              translation.x,
                              translation.y,
                              scale,
                              MediaQuery.of(context).size.height,
                              MediaQuery.of(context).size.width,
                            ),
                          );
                        },
                        enabled: !state.isWorking,
                        child: const Text('Set as background image'),
                      ),
                    ],
                  ),
                ),
                _buildLoadingSpinner(state),
              ],
            ),
          ),
        );
      },
    );
  }
}
