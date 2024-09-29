import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/widgets/auth-action-button.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/location_detector_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LocationAnalysis extends StatefulWidget {
  const LocationAnalysis({Key? key}) : super(key: key);

  @override
  LocationAnalysisState createState() => LocationAnalysisState();
}

class LocationAnalysisState extends State<LocationAnalysis> {
  String? imagePath;
  String? locationInfo = 'empty'; // 位置信息
  Size? imageSize;
  bool pictureTaken = false;
  bool _initializing = false;
  bool _bottomSheetVisible = false;

  // service injection
  LocationDetectorService _locationDetectorService = locator<LocationDetectorService>();
  CameraService _cameraService = locator<CameraService>();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  _start() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    setState(() => _initializing = false);
  }

  Future<bool> onShot() async {
    if (locationInfo == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('No locationInfo detected!'),
          );
        },
      );

      return false;
    } else {
      await Future.delayed(Duration(milliseconds: 500));

      if (_cameraService.cameraController?.value.isStreamingImages == true) {
        await _cameraService.cameraController?.stopImageStream();
      }

      XFile? file = await _cameraService.takePicture();
      imagePath = file?.path;

      if (imagePath != null) {
        File imageFile = File(imagePath!); 
        // 打印 imageFile 的路径
        print('Image File Path: ${imageFile.path}');
        final tags = await _locationDetectorService.getExifFromImage(imageFile); 
        locationInfo = _locationDetectorService.extractLocationFromExif(tags);
        // 打印位置信息
        print('Location Info: $locationInfo');
      }

      setState(() {
        _bottomSheetVisible = true;
        pictureTaken = true;
      });

      return true;
    }
  }


  // Future<bool> onShot() async {
  //   await Future.delayed(Duration(milliseconds: 500));
  //   XFile? file = await _cameraService.takePicture();
  //   imagePath = file?.path;

  //   if (imagePath != null) {
  //     File imageFile = File(imagePath!); // 将 String 类型的路径转换为 File
  //     final tags = await _locationDetectorService.getExifFromImage(imageFile); // 获取 Exif 信息
  //     String? extractedLocation = _locationDetectorService.extractLocationFromExif(tags); // 提取位置信息

  //     setState(() {
  //       locationInfo = extractedLocation.isNotEmpty ? extractedLocation : "无法获取位置信息";
  //       _bottomSheetVisible = true;
  //       pictureTaken = true;
  //     });
  //   }

  //   return true;
  // }

  _onBackPressed() {
    Navigator.of(context).pop();
  }

  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      pictureTaken = false;
      locationInfo = null; // 重置位置信息
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    late Widget body;

    if (_initializing) {
      body = Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_initializing && pictureTaken) {
      body = Column(
        children: [
          Container(
            width: width,
            height: height * 0.6, // 将图片的显示区域设定为屏幕的60%
            child: Transform(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Image.file(File(imagePath!)),
              ),
              transform: Matrix4.rotationY(mirror),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              locationInfo ?? "位置信息未获取到",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      );
    }

    if (!_initializing && !pictureTaken) {
      body = Transform.scale(
        scale: 1.0,
        child: AspectRatio(
          aspectRatio: MediaQuery.of(context).size.aspectRatio,
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                width: width,
                height:
                    width * _cameraService.cameraController!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CameraPreview(_cameraService.cameraController!),
                    // 你可以取消注释下面这段代码用于人脸检测等其他功能
                    // CustomPaint(
                    //   painter: FacePainter(
                    //       face: faceDetected, imageSize: imageSize!),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
        body: Stack(
          children: [
            body,
            CameraHeader(
              "LOCATION ANALYSIS",
              onBackPressed: _onBackPressed,
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_bottomSheetVisible
            ? AuthActionButton(
                onPressed: onShot,
                isLogin: false,
                reload: _reload,
              )
            : Container());
  }
}
