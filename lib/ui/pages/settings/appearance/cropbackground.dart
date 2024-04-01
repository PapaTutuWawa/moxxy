import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/cropbackground.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/backdrop_spinner.dart';
import 'package:moxxyv2/ui/widgets/cancel_button.dart';

class CropBackgroundPage extends StatefulWidget {
  const CropBackgroundPage({super.key});

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
    final width = query.size.width; // * query.devicePixelRatio;
    final height = query.size.height; // * query.devicePixelRatio;

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
    _controller ??=
        TransformationController(Matrix4.identity()..scale(q, q, 1));
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CropBackgroundCubit, CropBackgroundState>(
      builder: (BuildContext context, CropBackgroundState state) {
        return PopScope(
          canPop: !state.isWorking,
          onPopInvoked: (didPop) {
            if (didPop) {
              context.read<CropBackgroundCubit>().reset();
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                // ignore: prefer_if_elements_to_conditional_expressions
                state.imageHeight != 0 && state.imageWidth != 0
                    ? _buildImage(context, state)
                    : const SizedBox(),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: const Color.fromRGBO(0, 0, 0, 0),
                    child: CancelButton(
                      onPressed: () {
                        context.read<CropBackgroundCubit>().reset();
                        context.read<Navigation>().pop();
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
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(t.pages.cropbackground.blur),
                            ),
                            Switch(
                              value: state.blurEnabled,
                              onChanged: (_) {
                                if (state.isWorking) return;

                                context
                                    .read<CropBackgroundCubit>()
                                    .toggleBlur();
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
                      FilledButton(
                        onPressed: state.isWorking
                            ? null
                            : () {
                                final q = _scalingFactor(context, state);
                                final value = _controller == null
                                    ? (Matrix4.identity()..scale(q, q, 1))
                                    : _controller!.value;
                                final translation = value.getTranslation();
                                final scale = _controller == null
                                    ? 1.0
                                    : value.entry(0, 0);

                                context
                                    .read<CropBackgroundCubit>()
                                    .setBackground(
                                      translation.x,
                                      translation.y,
                                      scale,
                                      MediaQuery.of(context).size.height,
                                      MediaQuery.of(context).size.width,
                                    );
                              },
                        child: Text(t.pages.cropbackground.setAsBackground),
                      ),
                    ],
                  ),
                ),

                BackdropSpinner(
                  enabled: state.isWorking,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
