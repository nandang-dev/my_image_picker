import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';

class CameraComponent extends StatefulWidget {
  final CameraComponentController controller;
  final ValueChanged<XFile>? onConfirmImage;
  final Color? loadingColor;

  const CameraComponent(
      {Key? key,
      required this.controller,
      this.onConfirmImage,
      this.loadingColor})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CameraComponentState();
  }
}

class CameraComponentState extends State<CameraComponent> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CameraComponentValue>(
      valueListenable: widget.controller,
      builder: (c, d, w) {
        if (d.cameraController == null) {
          widget.controller.initCamera();
        }
        return childBuilder(d.state);
      },
    );
  }

  Widget childBuilder(CameraComponensStates state) {
    switch (state) {
      case CameraComponensStates.onInitializeCamera:
        return initializeWidget();
      case CameraComponensStates.onOpenedCamera:
        return openedCameraWidget();
      case CameraComponensStates.onLoadedImage:
        return loadedImageWidget();
    }
  }

  Widget initializeWidget() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: CircularProgressIndicator(
            color: widget.loadingColor ?? Theme.of(context).primaryColor),
      ),
    );
  }

  Widget openedCameraWidget() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 20),
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CameraPreview(
                  widget.controller.value.cameraController!,
                ),
              ),
            ),
          ),
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.changeFlashMode();
                      },
                      child: ValueListenableBuilder<CameraValue>(
                        valueListenable:
                            widget.controller.value.cameraController!,
                        builder: (c, d, w) {
                          return Icon(
                            widget.controller.value.cameraController!.value
                                        .flashMode ==
                                    FlashMode.auto
                                ? Icons.flash_auto
                                : widget.controller.value.cameraController!
                                            .value.flashMode ==
                                        FlashMode.torch
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                            color: Colors.white,
                            size: 30,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.takePicture();
                      },
                      child: const Icon(
                        Icons.brightness_1_rounded,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.changeCamera();
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: ValueListenableBuilder<CameraValue>(
                        valueListenable:
                            widget.controller.value.cameraController!,
                        builder: (c, d, w) {
                          return const Icon(
                            Icons.sync,
                            color: Colors.white,
                            size: 30,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget loadedImageWidget() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.only(top: 20),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PhotoView(
                  enableRotation: true,
                  imageProvider: FileImage(
                      File(widget.controller.value.captured?.path ?? "")),
                  errorBuilder: (b, o, s) {
                    return const Center(
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller
                            .setState(CameraComponensStates.onOpenedCamera);
                      },
                      child: const Icon(
                        FontAwesomeIcons.circleXmark,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.value.cameraController!
                            .dispose()
                            .then((value) => null);
                        if (widget.onConfirmImage != null) {
                          widget.onConfirmImage!(
                              widget.controller.value.captured!);
                        } else {
                          Navigator.of(context)
                              .pop(widget.controller.value.captured);
                        }
                      },
                      child: const Icon(
                        FontAwesomeIcons.circleCheck,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.value.cameraController?.dispose();
    super.dispose();
  }
}

class CameraComponentController extends ValueNotifier<CameraComponentValue> {
  CameraComponentController({
    CameraComponentValue? value,
  }) : super(
          value ?? CameraComponentValue(),
        );

  void initCamera({
    CameraDescription? cameraDescription,
  }) {
    setState(CameraComponensStates.onInitializeCamera);
    value.cameraController?.dispose();
    availableCameras().then(
      (availableCamera) {
        value.cameraDescriptions = availableCamera;
        value.selectedCamera =
            cameraDescription ?? value.cameraDescriptions?.first;
        value.cameraController = CameraController(
          value.selectedCamera!,
          ResolutionPreset.max,
          enableAudio: false,
        );
        value.cameraController
            ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
        value.cameraController?.initialize().then(
          (camera) {
            value.cameraController?.setFlashMode(value.flashMode);
            setState(CameraComponensStates.onOpenedCamera);
          },
        );
      },
    );
  }

  void changeCamera() {
    if ((value.cameraDescriptions?.length ?? 0) > 1) {
      int indexCamra =
          (value.cameraDescriptions)!.indexOf(value.selectedCamera!);
      if ((indexCamra + 1) <= (value.cameraDescriptions ?? []).length - 1) {
        value.cameraController!.dispose().then(
          (dispose) {
            initCamera(
              cameraDescription: value.cameraDescriptions?[(indexCamra + 1)],
            );
          },
        );
      } else {
        value.cameraController!.dispose().then(
          (dispose) {
            initCamera(
              cameraDescription: value.cameraDescriptions?.first,
            );
          },
        );
      }
    }
  }

  void changeFlashMode() {
    if (value.flashMode == FlashMode.off) {
      setFlashMode(FlashMode.auto);
    } else if (value.flashMode == FlashMode.auto) {
      setFlashMode(FlashMode.torch);
    } else {
      setFlashMode(FlashMode.off);
    }
  }

  void setFlashMode(FlashMode mode) {
    value.cameraController?.setFlashMode(mode);
    value.flashMode = mode;
    commit();
  }

  void takePicture() {
    value.cameraController?.takePicture().then(
      (image) {
        value.captured = image;
        setState(CameraComponensStates.onLoadedImage);
      },
    );
  }

  void setState(CameraComponensStates state) {
    value.state = state;
    commit();
  }

  void commit() {
    notifyListeners();
  }
}

class CameraComponentValue {
  CameraComponensStates state = CameraComponensStates.onInitializeCamera;
  CameraController? cameraController;
  List<CameraDescription>? cameraDescriptions;
  CameraDescription? selectedCamera;
  FlashMode flashMode = FlashMode.off;

  XFile? captured;
}

enum CameraComponensStates {
  onInitializeCamera,
  onOpenedCamera,
  onLoadedImage,
}
