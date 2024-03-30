import 'package:cropperx/cropperx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/backdrop_spinner.dart';
import 'package:moxxyv2/ui/widgets/cancel_button.dart';

class CropPage extends StatelessWidget {
  const CropPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const CropPage(),
        settings: const RouteSettings(
          name: cropRoute,
        ),
      );

  Widget _buildImageBody(BuildContext context, CropState state) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Cropper(
            backgroundColor: Colors.black,
            image: Image.memory(state.image!),
            cropperKey: context.read<CropBloc>().cropKey,
            overlayType: OverlayType.circle,
          ),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Material(
            color: const Color.fromRGBO(0, 0, 0, 0),
            child: CancelButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: state.isWorking
                    ? null
                    : () async {
                        context.read<CropBloc>().add(
                              ImageCroppedEvent(),
                            );
                      },
                child: Text(t.pages.crop.setProfilePicture),
              ),
            ],
          ),
        ),
        BackdropSpinner(
          enabled: state.isWorking,
        ),
      ],
    );
  }

  Widget _buildLoadingBody() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CropBloc, CropState>(
      builder: (context, state) {
        return PopScope(
          onPopInvoked: (_) {
            context.read<CropBloc>().add(ResetImageEvent());
          },
          child: SafeArea(
            child: state.image != null
                ? _buildImageBody(context, state)
                : _buildLoadingBody(),
          ),
        );
      },
    );
  }
}
