import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:moduletwodemo/httpUtility.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? cameraController;
  bool camInitialized = false;
  final String backendServer =
      "8u3ua4o5od.execute-api.ap-south-1.amazonaws.com";
  final String backendReceiver = "/s3UploadDelpoy/pic";

  Future<void> disposeCamController() async {
    final CameraController? oldcontroller = cameraController;
    if (oldcontroller != null) {
      cameraController = null;
      camInitialized = false;
      return oldcontroller.dispose();
    } else {
      return;
    }
  }

  createCamController() {
    availableCameras().then(
      (value) {
        cameras = value;
        cameraController = CameraController(cameras[0], ResolutionPreset.max,
            enableAudio: false, imageFormatGroup: ImageFormatGroup.bgra8888);
        cameraController?.initialize().then((_) {
          setState(() {
            camInitialized = true;
          });
        }).catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                debugPrint("CameraAccessDenied");
                break;
              default:
                debugPrint("Sabh sahi");
                break;
            }
            print("Camera Exception");
            print(e);
          }
        });
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    createCamController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    disposeCamController();
    super.dispose();
  }

  void takePicture(BuildContext context) {
    if (cameraController != null) {
      // showSnackBar(context, "Sending Picture for Validation", false);
      debugPrint("Sending Picture for Validation");
      cameraController!.pausePreview();
      Future.delayed(const Duration(milliseconds: 400), (() {
        cameraController!.resumePreview();
      }));
      cameraController!.takePicture().then((raw) {
        transformPicture(raw).then((xfile) {
          xfile!.readAsBytes().then((bytes) async {
            HttpUtility hu = HttpUtility();
            hu
                .httpPost(
                    server: backendServer,
                    path: backendReceiver,
                    queryParams: {},
                    payload: bytes,
                    headers: {'Content-Type': 'image/png'})
                .then((value) {
              // showSnackBar(context,"Picture Sent",true);
              debugPrint("Picture Sent");
            }).onError((error, stackTrace) {
              // showSnackBar(context, "UploadFailed", true);
              debugPrint("UploadFailed");
            });
          });
        });
      });
    }
  }

  // Future<XFile?> transformPicture(XFile jpeg) async {
  //   final completer = Completer<XFile>();
  //   jpeg.readAsBytes().then((value) {
  //     img.Image i = img.JpegDecoder().decode(value)!;
  //     img.Image sqr = img.copyResizeCropSquare(i, size: 512);
  //     Uint8List png = img.encodePng(sqr);
  //     XFile res = XFile.fromData(png);
  //     completer.complete(res);
  //   }).onError((error, stackTrace) {
  //     print("Couldn't Transform Picture");
  //   });
  //   print(completer.future);
  //   return completer.future;
  // }

  Future<XFile?> transformPicture(XFile jpeg) async {
    final completer = Completer<XFile>();

    try {
      final Uint8List bytes = await jpeg.readAsBytes();
      final img.Image image = img.decodeJpg(bytes)!;
      final img.Image squareImage = img.copyResizeCropSquare(image, size: 512);
      final Uint8List pngBytes = img.encodePng(squareImage);
      final XFile res = XFile.fromData(pngBytes);
      completer.complete(res);
    } catch (error) {
      print("Couldn't transform the picture: $error");
      completer.completeError(error);
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Camera Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            child: (camInitialized)
                ? CameraPreview(
                    cameraController!,
                    child: LayoutBuilder(
                        builder: (BuildContext context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                      );
                    }),
                  )
                : Container(),
          ),
        )
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 100,
        width: 100,
        child: FittedBox(
            child: FloatingActionButton(
          onPressed: () {
            takePicture(context);
          },
          child: Icon(Icons.camera_alt_outlined),
        )),
      ),
    );
  }
}
