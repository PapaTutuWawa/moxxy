import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

const cropperHeightFraction = 0.6;

class CropBackgroundPage extends StatelessWidget {

  CropBackgroundPage({ Key? key }) : _controller = CropController(), super(key: key);
  final CropController _controller;
  
  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(builder: (context) => CropBackgroundPage());

  Widget _buildImage(BuildContext context, Uint8List? bytes) {
    final size = MediaQuery.of(context).size;

    if (bytes == null) {
      return SizedBox(
        width: size.width,
        height: size.height * cropperHeightFraction,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      width: size.width,
      height: size.height * cropperHeightFraction,
      child: Crop(
        image: bytes,
        controller: _controller,
        onCropped: (image) {
          context.read<CropBackgroundBloc>().add(BackgroundSetEvent(image));
        },
        aspectRatio: size.width / size.height,
        initialSize: 0.8,
        baseColor: Colors.black,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CropBackgroundBloc, CropBackgroundState>(
      builder: (BuildContext context, CropBackgroundState state) => WillPopScope(
        onWillPop: () async {
          context.read<CropBackgroundBloc>().add(CropBackgroundResetEvent());
          return true;
        },
        child: Scaffold(
          appBar: BorderlessTopbar.justBackButton(),
          body: Column(
            children: [
              _buildImage(context, state.image),
              IntrinsicWidth(
                child: Row(
                  children: [
                    const Text('Blur image'),
                    Switch(
                      value: state.blurEnabled,
                      onChanged: (_) {
                        if (state.image == null) return;
                        
                        context.read<CropBackgroundBloc>().add(BlurToggledEvent());
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: state.image != null ? _controller.crop : () {},
                  child: const Text('Set as chat background'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
