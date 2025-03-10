library my_image_picker;

import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_image_picker/file_service.dart';
import 'package:my_image_picker/my_camera.dart';
import 'package:my_image_picker/type.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerComponent extends StatelessWidget {
  final ImagePickerController controller;
  final bool? camera;
  final bool? galery;
  final WidgetFromDataBuilder2<WidgetBuilder, ImagePickerValue>? container;
  final WidgetFromDataBuilder<ImagePickerValue>? placeHolderContainer;
  final WidgetFromDataBuilder<ImagePickerValue>? imageContainer;
  final WidgetFromDataBuilder<VoidCallback>? buttonCamera;
  final WidgetFromDataBuilder<VoidCallback>? buttonGalery;
  final WidgetFromDataBuilder2<VoidCallback, VoidCallback>? popUpChild;
  final Alignment? popUpAlign;
  final BoxDecoration? popUpDecoration;
  final EdgeInsetsGeometry? popUpMargin;
  final EdgeInsetsGeometry? popUpPadding;
  final double? popUpHeight;
  final double? popUpWidth;
  final ValueChanged<ImagePickerController>? onTap;
  final bool? readOnly;
  final double? containerHeight;
  final double? containerWidth;
  final int? imageQuality;
  final int? compressImageQuality;
  final String? uploadUrl;
  final String? uploadField;
  final String? descriptionField;
  final String? deleteUrl;
  final String? token;
  final ValueChanged<String>? onUploaded;
  final ValueChanged<dynamic>? onUploadFailed;
  final bool? checkRequirement;
  final int? minimumMemoryRequirement;
  final int? minimumDiskRequrement;
  final int? minimumBatteryRequrement;
  final ValueChanged<File?>? onImageLoaded;
  final VoidCallback? onStartGetImage;
  final VoidCallback? onEndGetImage;
  final String? selectPhotoLabel;
  final String? openCameraLabel;
  final String? openGaleryLabel;
  final ValueChanged<ImagePickerController>? onChange;
  final String? addDescriptionLabel;
  final String? saveLabel;
  final String? cancelLabel;
  final bool? canReupload;
  final bool? showDescription;
  final bool useDescriptionFieldAsQuery;
  final bool isDirectUpload;

  ImagePickerComponent({
    super.key,
    required this.controller,
    this.camera = true,
    this.galery = true,
    this.container,
    this.placeHolderContainer,
    this.imageContainer,
    this.buttonCamera,
    this.buttonGalery,
    this.popUpChild,
    this.popUpAlign,
    this.popUpDecoration,
    this.popUpMargin,
    this.popUpPadding,
    this.popUpHeight,
    this.popUpWidth,
    this.onTap,
    this.readOnly = false,
    @required this.containerHeight,
    @required this.containerWidth,
    this.imageQuality,
    this.compressImageQuality,
    this.uploadUrl,
    this.deleteUrl,
    this.uploadField,
    this.onUploaded,
    this.token,
    this.onUploadFailed,
    this.checkRequirement = true,
    this.minimumMemoryRequirement = 500,
    this.minimumDiskRequrement = 500,
    this.minimumBatteryRequrement = 10,
    this.onImageLoaded,
    this.onStartGetImage,
    this.onEndGetImage,
    this.selectPhotoLabel,
    this.openCameraLabel,
    this.openGaleryLabel,
    this.onChange,
    this.addDescriptionLabel = "Add Description",
    this.saveLabel = "Save",
    this.cancelLabel = "Cancel",
    this.canReupload = true,
    this.showDescription = true,
    this.useDescriptionFieldAsQuery = true,
    this.isDirectUpload = false,
    this.descriptionField,
  }) {
    if (isDirectUpload) {
      assert(uploadUrl != null && uploadUrl!.isNotEmpty,
          "uploadUrl must be provided when isDirectUpload is true");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ImagePickerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        controller.value.context = context;
        controller.value.quality = compressImageQuality ?? 25;
        if (showDescription == true) {
          controller.value.beforeUpload = () {
            return showModalDescription(context);
          };
        }
        return GestureDetector(
          onTap: readOnly == false
              ? onTap != null
                  ? () {
                      onTap?.call(controller);
                    }
                  : () {
                      if (!(checkRequirement ?? true)) return;
                      if (value.isUploaded && canReupload == false) return;
                      memorySpaceCheck(context).then((result) {
                        if (result == true) {
                          if (value.state !=
                              ImagePickerComponentState.Disable) {
                            if (camera == true && galery == true) {
                              // ignore: use_build_context_synchronously
                              openModal(context);
                            } else if (camera == true) {
                              controller.getImages(
                                camera: true,
                                imageQuality: imageQuality ?? 30,
                                onImageLoaded: onImageLoaded,
                                onStartGetImage: onStartGetImage,
                                onEndGetImage: onEndGetImage,
                                onChange: onChange,
                                isDirectUpload: isDirectUpload
                                    ? uploadUrl == null || uploadUrl != ""
                                        ? true
                                        : false
                                    : false,
                              );
                            } else if (galery == true) {
                              controller.getImages(
                                camera: false,
                                imageQuality: imageQuality ?? 30,
                                onImageLoaded: onImageLoaded,
                                onStartGetImage: onStartGetImage,
                                onEndGetImage: onEndGetImage,
                                onChange: onChange,
                                isDirectUpload: isDirectUpload
                                    ? uploadUrl == null || uploadUrl != ""
                                        ? true
                                        : false
                                    : false,
                              );
                            }
                          }
                        }
                      });
                    }
              : () {},
          child: container != null
              ? container!((context) {
                  return widgetBuilder(value, context);
                }, value)
              : Center(
                  child: Container(
                    height: containerHeight ?? 100,
                    width: containerWidth ?? 100,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: stateColor(context, value.state),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    child: Center(
                      child: widgetBuilder(value, context),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void openModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      elevation: 1,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.red.withValues(alpha: 0),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop("modal");
          },
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.grey.withValues(alpha: 0.0),
            child: Align(
              alignment: popUpAlign ?? Alignment.bottomCenter,
              child: Container(
                height: popUpHeight ?? 170,
                width: popUpWidth ?? double.infinity,
                margin: popUpMargin ??
                    (popUpAlign == Alignment.center
                        ? const EdgeInsets.only(left: 10, right: 20)
                        : null),
                padding: popUpPadding ?? const EdgeInsets.all(20),
                decoration: popUpDecoration ??
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: popUpAlign == Alignment.center
                            ? const Radius.circular(20)
                            : Radius.zero,
                        bottomRight: popUpAlign == Alignment.center
                            ? const Radius.circular(20)
                            : Radius.zero,
                      ),
                    ),
                child: popUpChild != null
                    ? popUpChild!(() {
                        openCamera(context);
                      }, () {
                        openGalery(context);
                      })
                    : Column(
                        children: <Widget>[
                          Text(
                            selectPhotoLabel ?? "Select Photo",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          buttonGalery != null
                              ? buttonGalery!(() {
                                  openGalery(context);
                                })
                              : SizedBox(
                                  height: 35,
                                  width: 200,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      openCamera(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Text(openCameraLabel ?? "Camera",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                            )),
                                  ),
                                ),
                          const SizedBox(
                            height: 10,
                          ),
                          buttonGalery != null
                              ? buttonGalery!(() {
                                  openGalery(context);
                                })
                              : SizedBox(
                                  height: 35,
                                  width: 200,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      openGalery(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Text(openGaleryLabel ?? "Gallery",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                            )),
                                  ),
                                ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void openGalery(BuildContext context) {
    Navigator.of(context).pop();
    if (!(checkRequirement ?? true)) return;
    memorySpaceCheck(context).then((result) {
      if (result == true) {
        controller.getImages(
          camera: false,
          imageQuality: imageQuality ?? 30,
          onImageLoaded: onImageLoaded,
          onStartGetImage: onStartGetImage,
          onEndGetImage: onEndGetImage,
          onChange: onChange,
          isDirectUpload: isDirectUpload
              ? uploadUrl == null || uploadUrl != ""
                  ? true
                  : false
              : false,
        );
      }
    });
  }

  void openCamera(BuildContext context) {
    Navigator.of(context).pop();
    if (!(checkRequirement ?? true)) return;
    memorySpaceCheck(context).then((result) {
      if (result == true) {
        controller.getImages(
          camera: true,
          imageQuality: imageQuality ?? 30,
          onImageLoaded: onImageLoaded,
          onStartGetImage: onStartGetImage,
          onEndGetImage: onEndGetImage,
          onChange: onChange,
          isDirectUpload: isDirectUpload
              ? uploadUrl == null || uploadUrl != ""
                  ? true
                  : false
              : false,
        );
      }
    });
  }

  static Color stateColor(
      BuildContext context, ImagePickerComponentState state) {
    return state == ImagePickerComponentState.Disable
        ? Theme.of(context).disabledColor
        : state == ImagePickerComponentState.Error
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;
  }

  Widget widgetBuilder(ImagePickerValue value, BuildContext context) {
    return SizedBox(
      child: Stack(
        children: [
          Center(
            child: value.loadData
                ? !(uploadUrl == null || uploadUrl == "") && !value.isUploaded
                    ? prepearingUpload(value, context, onChange!)
                    : immageWidget(value)
                : placeHolderContainer != null
                    ? placeHolderContainer!(value)
                    : placeHolder(),
          ),
        ],
      ),
    );
  }

  Widget prepearingUpload(ImagePickerValue value, BuildContext context,
      ValueChanged<ImagePickerController> onChange) {
    if (value.onProgressUpload == false &&
        value.state == ImagePickerComponentState.Enable) {
      controller.uploadFile(
        uploadUrl ?? "",
        uploadField ?? "file",
        descriptionField,
        token: token ?? "",
        useDescriptionFieldAsQuery: useDescriptionFieldAsQuery,
        onUploaded: (resut) {
          if (onUploaded != null) {
            onUploaded!(resut);
          } else {
            debugPrint("Upload Success");
            debugPrint(resut);
          }
        },
        onUploaderror: (onError) {
          if (onUploadFailed != null) {
            onUploadFailed!(onError);
          } else {
            debugPrint("Upload Success");
            debugPrint(onError);
          }
        },
        onChange: onChange,
      );
    }
    return uploadProgressWidget(value, context);
  }

  Widget uploadProgressWidget(ImagePickerValue value, BuildContext context) {
    return SizedBox(
      child: Stack(
        children: [
          immageWidget(value),
          Container(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(
                  left: (containerWidth ?? 100) * 10 / 100,
                  right: (containerWidth ?? 100) * 10 / 100),
              padding: const EdgeInsets.all(0),
              width: containerWidth,
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  )),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: value.onProgressUpload ? 500 : 1,
                  ),
                  width: (containerWidth ?? 100) *
                      (controller.percentageUpload / 100),
                  decoration: BoxDecoration(
                    color: value.state != ImagePickerComponentState.Error
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: value.state == ImagePickerComponentState.Error
                ? Container(
                    margin:
                        EdgeInsets.only(top: (containerHeight ?? 100) / 2 + 15),
                    child: Text(
                      "Upload Failed",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  )
                : const SizedBox(),
          )
        ],
      ),
    );
  }

  Widget immageWidget(ImagePickerValue value) {
    return SizedBox(
      child: Stack(
        children: [
          imageContainer != null
              ? imageContainer!(value)
              : value.uploadedUrl == null || value.uploadedUrl == ""
                  ? memoryImageMode(value)
                  : networkImageMode(value),
          showDescription == false
              ? const SizedBox()
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {
                      if (uploadUrl != null && uploadUrl != "") return;
                      showModalDescription(value.context!);
                    },
                    child: Container(
                      color: Theme.of(value.context!)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.9),
                      padding: const EdgeInsets.all(5),
                      width: double.infinity,
                      height: 25,
                      child: Center(
                        child: Text(
                          value.imageDescription ?? "add description",
                          textAlign: TextAlign.center,
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  Widget memoryImageMode(ImagePickerValue value) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: value.valueUri != null
          ? BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(value.valueUri!.contentAsBytes()),
              ),
            )
          : null,
    );
  }

  Widget networkImageMode(ImagePickerValue value) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(value.uploadedUrl ?? ""),
        ),
      ),
    );
  }

  Widget placeHolder() {
    return placeHolderContainer != null
        ? placeHolderContainer!(controller.value)
        : const Icon(
            Icons.camera_alt,
            color: Colors.grey,
            size: 50,
          );
  }

  Future<bool> memorySpaceCheck(BuildContext context) async {
    // controller.value.loadingController.startLoading();
    bool result = true;
    return result;
    // return EnvironmentUtil.readDevice.then((value) {
    //   controller.value.loadingController.stopLoading();
    //   // if (value.os == "Android") {
    //   //   if (value?.memory?.freeMemory ??
    //   //       minimumMemoryRequirement < minimumMemoryRequirement) {
    //   //     openModalErrorMessage(context,
    //   //         title: System.data.resource.notEnoughMemory,
    //   //         body:
    //   //             "${minimumMemoryRequirement / 1000} GB ${System.data.resource.ofmemoryisrequiredtorunthisprocess}, ${value.memory.freeMemory / 1000} GB ${System.data.resource.ofmemoryremains}");
    //   //     result = false;
    //   //   }
    //   // }
    //   // print("disk ${value.diskSpace.free ?? 0} < $minimumDiskRequrement");
    //   // if (value.diskSpace.free ?? 0 < minimumDiskRequrement) {
    //   //   openModalErrorMessage(context,
    //   //       title: System.data.resource.notEnoughDisk,
    //   //       body:
    //   //           "${minimumDiskRequrement / 1000} GB ${System.data.resource.ofDiskRequiredtorunthisprocess}, ${NumberFormat("#.##").format(value.diskSpace.free ?? 0 / 1000)} GB ${System.data.resource.ofdiskremain}");
    //   //   result = false;
    //   // }
    //   // if (value?.battrey ??
    //   //     minimumBatteryRequrement < minimumBatteryRequrement) {
    //   //   openModalErrorMessage(context,
    //   //       title: System.data.resource.batteryLow,
    //   //       body:
    //   //           "${System.data.resource.pleaseConnectTheDevicetoApowerSource}");
    //   //   result = false;
    //   // }
    //   return result;
    // }).catchError((onError) {
    //   openModalErrorMessage(
    //     context,
    //     title: "${System.data.resource.checkingMemorySpaceError}",
    //     body: "$onError",
    //   );
    //   return false;
    // });
  }

  Future<bool> showModalDescription(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 10,
              right: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.text,
                        controller: TextEditingController(
                          text: (controller.value.imageDescription ?? '')
                              .toString(),
                        )..selection = TextSelection.collapsed(
                            offset: ((controller.value.imageDescription ?? '')
                                    .toString())
                                .length),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          hintText: addDescriptionLabel ?? "Add Description",
                          hintStyle: Theme.of(context).textTheme.labelMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              width: 1,
                            ),
                          ),
                        ),
                        onSaved: (value) {
                          controller.value.imageDescription = value;
                          controller.commit();
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            alignment: Alignment.center,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(
                            cancelLabel ?? "Cancel",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            alignment: Alignment.center,
                          ),
                          onPressed: () {
                            formKey.currentState!.save();
                            Navigator.of(context).pop(true);
                          },
                          child: Text(
                            saveLabel ?? "Save",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    ).then((onValue) {
      return onValue;
    });
  }
}

class ImagePickerController extends ValueNotifier<ImagePickerValue> {
  ImagePickerController({ImagePickerValue? value})
      : super(value ?? ImagePickerValue());

  String? getExtension(String string) {
    List<String> getList = string.split(".");
    String data = getList.last.replaceAll("'", "");
    String? result;
    if (data == "png") {
      result = "data:image/png;base64,";
    } else if (data == "jpeg") {
      result = "data:image/jpeg;base64,";
    } else if (data == "jpg") {
      result = "data:image/jpg;base64,";
    } else if (data == "gif") {
      result = "data:image/gif;base64,";
    }
    return result;
  }

  /// The `imageQuality` argument modifies the quality of the image, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the image with
  /// the original quality will be returned. Compression is only supportted for certain
  /// image types such as JPEG. If compression is not supported for the image that is picked,
  /// an warning message will be logged.
  Future<bool> getImages({
    bool camera = true,
    int imageQuality = 30,
    ValueChanged<File?>? onImageLoaded,
    BuildContext? context,
    VoidCallback? onStartGetImage,
    VoidCallback? onEndGetImage,
    ValueChanged<ImagePickerController>? onChange,
    required bool isDirectUpload,
  }) async {
    onStartGetImage?.call();
    try {
      PickedFile? picker;
      if (camera) {
        PermissionStatus access = await Permission.camera.status;
        if (access.isGranted == true) {
          // picker = await ImagePicker()
          //     // ignore: deprecated_member_use
          //     .getImage(source: ImageSource.camera, imageQuality: imageQuality);
          // ignore: use_build_context_synchronously
          picker = await openCamrea(
            value.context!,
          );
        } else {
          // ignore: use_build_context_synchronously
          openModalErrorMessage(
            value.context!,
            title: "Permission Required",
            body: "Please allow this app to access your camera to continue",
          );
        }
      } else {
        await Permission.photos.request();
        PermissionStatus access2 = await Permission.photos.status;
        if (access2.isGranted == true) {
          XFile? xFile = await ImagePicker().pickImage(
              imageQuality: imageQuality, source: ImageSource.gallery);
          picker = PickedFile(xFile!.path);
        } else {
          openModalErrorMessage(
            value.context!,
            title: "Permission Required",
            body: "Please allow this app to access your gallery to continue",
          );
        }
      }

      File image = File(picker!.path);
      if (image.path.isEmpty) {
        throw "Image path is empty";
      }

      String valueBase64Compress = "";
      value.fileImage = image;
      String extention = getExtension(image.toString())!;
      value.base64 = extention! + base64.encode(image.readAsBytesSync());
      notifyListeners();

      return await FlutterImageCompress.compressWithFile(
        image.absolute.path,
        quality: value.quality,
      ).then((a) async {
        bool doUpload = true;
        if (value.beforeUpload != null) {
          doUpload = await value.beforeUpload!();
        }

        if (doUpload == false) {
          clear();
          return false;
        }

        valueBase64Compress =
            getExtension(image.toString())! + base64.encode(a!);
        value.base64Compress = valueBase64Compress;
        value.base64 = valueBase64Compress;
        value.loadData = true;
        value.valueUri = Uri.parse(valueBase64Compress).data!;
        value.isUploaded = false;
        value.uploadedUrl = null;
        value.state = ImagePickerComponentState.Enable;
        getBase64();
        notifyListeners();
        if (onImageLoaded != null) {
          onImageLoaded(value.fileImage);
        }
        if (!isDirectUpload) onChange?.call(this);
        return true;
      }).catchError((e) {
        value.error = e;
        notifyListeners();
        onChange?.call(this);
        return false;
      }).whenComplete(() {
        onEndGetImage?.call();
      });
    } catch (e) {
      value.error = "error on get picture";
      value.isUploaded = true;
      value.state = ImagePickerComponentState.Error;
      commit();
      rethrow;
    }
  }

  String? getBase64() {
    return value.base64;
  }

  UriData? getUriData() {
    return value.valueUri;
  }

  String? getBase64Compress() {
    return value.base64Compress;
  }

  File? getFile() {
    return value.fileImage;
  }

  void clear() {
    value.fileImage = null;
    value.base64 = null;
    value.base64Compress = null;
    notifyListeners();
  }

  List<Object?> getAll() {
    List<Object?> list = [value.base64, value.base64Compress, value.fileImage];
    return list;
  }

  String getFileName() {
    List<String> getList = value.fileImage.toString().split("-");
    String data = getList.last.replaceAll("'", "");
    return data == "null" ? "" : data;
  }

  set state(ImagePickerComponentState state) {
    value.state = state;
    notifyListeners();
  }

  void disposes() {
    value.loadData = false;
    value.valueUri = null;
    value.base64Compress = null;
    value.base64 = null;
    value.fileImage = null;
    value.error = null;
    notifyListeners();
  }

  bool validate() {
    // if (isValid && value.isUploaded) {
    //   value.state = ImagePickerComponentState.Enable;
    //   commit();
    //   return true;
    // } else {
    //   value.state = ImagePickerComponentState.Error;
    //   commit();
    //   return false;
    // }
    return true;
  }

  bool get isValid {
    bool isValid = (getBase64() == null || getBase64() == "") ? false : true;
    isValid = isValid == false
        ? value.uploadedUrl == null || value.uploadedUrl == ""
            ? false
            : true
        : isValid;
    return isValid;
  }

  double get percentageUpload {
    return (value.fileSize == 0
            ? 0
            : (value.uploadedSize / value.fileSize) * 100)
        .toDouble();
  }

  void uploadFile(
    String url,
    String field,
    String? descriptionField, {
    String token = "",
    ValueChanged<String>? onUploaded,
    ValueChanged<dynamic>? onUploaderror,
    required bool useDescriptionFieldAsQuery,
    required ValueChanged<ImagePickerController> onChange,
  }) async {
    if (value.fileImage == null) {
      return;
    }

    try {
      debugPrint("upload url... $url");
      value.uploadedSize = 0;
      value.fileSize = 0;
      value.isUploaded = false;
      commit();
      await FileServiceUtil.fileUploadMultipart(
        field: field,
        file: value.fileImage,
        url: url,
        token: token,
        description: value.imageDescription,
        descriptionField: descriptionField,
        onUploadProgress: (
          uploaded,
          fileSize,
        ) {
          value.onProgressUpload = true;
          value.uploadedSize = uploaded;
          value.fileSize = fileSize;
          value.state = ImagePickerComponentState.Disable;
          debugPrint(
              "process... ${value.uploadedSize} ${value.fileSize} $percentageUpload");
          commit();
        },
        useDescriptionFieldAsQuery: useDescriptionFieldAsQuery,
      ).then((result) {
        value.uploadedSize = 0;
        value.fileSize = 0;
        value.onProgressUpload = false;
        value.isUploaded = true;
        value.uploadedResponse = result;
        setUploadedUrl();
        setfilePath();
        setUploadedId();
        value.state = ImagePickerComponentState.Enable;
        onUploaded?.call(result);
        commit();
        onChange(this);
      }).catchError((e) {
        debugPrint(e.toString());
        value.isUploaded = false;
        value.onProgressUpload = false;
        value.state = ImagePickerComponentState.Error;
        commit();
        if (onUploaderror != null) onUploaderror(e);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void setUploadedUrl({String? jsonKey}) {
    value.uploadedUrl =
        json.decode(value.uploadedResponse.toString())[jsonKey ?? "fileUrl"];
  }

  void setfilePath({String? jsonKey}) {
    value.filePath =
        json.decode(value.uploadedResponse.toString())[jsonKey ?? "filePath"];
  }

  void setUploadedId({String? jsonKey}) {
    value.uploadedId =
        json.decode(value.uploadedResponse.toString())[jsonKey ?? "imageId"];
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void openModalErrorMessage(
    BuildContext context, {
    String? title,
    String? body,
    AlignmentGeometry? popUpAlign,
    double? popUpHeight,
    double? popUpWidth,
    EdgeInsetsGeometry? popUpMargin,
    EdgeInsetsGeometry? popUpPadding,
    Decoration? popUpDecoration,
  }) {
    showModalBottomSheet(
      context: context,
      elevation: 1,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.red.withValues(alpha: 0),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop("modal");
          },
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.grey.withValues(alpha: 0.0),
            child: Align(
              alignment: popUpAlign ?? Alignment.bottomCenter,
              child: Container(
                height: popUpHeight ?? 170,
                width: popUpWidth ?? double.infinity,
                margin: popUpMargin ??
                    (popUpAlign == Alignment.center
                        ? const EdgeInsets.only(left: 10, right: 20)
                        : const EdgeInsets.only(left: 10, right: 20)),
                padding: popUpPadding ?? const EdgeInsets.all(20),
                decoration: popUpDecoration ??
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: popUpAlign == Alignment.center
                            ? const Radius.circular(20)
                            : Radius.zero,
                        bottomRight: popUpAlign == Alignment.center
                            ? const Radius.circular(20)
                            : Radius.zero,
                      ),
                    ),
                child: Column(
                  children: <Widget>[
                    Text(
                      "$title",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      "$body",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<PickedFile> openCamrea(
    BuildContext context, {
    CameraDescription? cameraDescription,
  }) {
    return showDialog<PickedFile>(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          color: Colors.transparent,
          height: double.infinity,
          width: double.infinity,
          child: CameraComponent(
            controller: CameraComponentController(),
            onConfirmImage: (image) {
              Navigator.of(ctx).pop(PickedFile(image.path));
            },
          ),
        );
      },
    ).then(
      (value) {
        return value ?? PickedFile("");
      },
    );
  }

  void commit() {
    notifyListeners();
  }
}

class ImagePickerValue {
  BuildContext? context;
  bool loadData;
  bool isUploaded = true;
  bool onProgressUpload = false;
  dynamic uploadedResponse;
  String? uploadedUrl;
  String? filePath;
  dynamic uploadedId;
  String? base64Compress;
  String? imageDescription;
  String? base64;
  UriData? valueUri;
  File? fileImage;
  int quality;
  String? error;
  ImagePickerComponentState state;
  int uploadedSize = 0;
  int fileSize = 0;
  Future<bool> Function()? beforeUpload;

  ImagePickerValue({
    this.loadData = false,
    this.base64Compress,
    this.base64,
    this.quality = 25,
    this.valueUri,
    this.error,
    this.uploadedUrl,
    this.filePath,
    this.uploadedId,
    this.imageDescription,
    this.state = ImagePickerComponentState.Enable,
  });
}

enum ImagePickerComponentState {
  // ignore: constant_identifier_names
  Enable,
  // ignore: constant_identifier_names
  Disable,
  // ignore: constant_identifier_names
  Error,
}
