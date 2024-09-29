import 'dart:async';
import 'dart:io';
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
  String? locationInfo = 'Location info will appear here'; // 初始化位置信息
  CameraService _cameraService = locator<CameraService>();
  LocationDetectorService _locationDetectorService = locator<LocationDetectorService>();
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;
  String? imagePath; // 图片路径

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

  Future<void> _start() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    setState(() => _isInitializing = false);
  }

  /// 拍照并获取位置信息
  Future<void> takePictureAndDetectLocation() async {
    try {
      XFile? file = await _cameraService.takePicture(); // 拍照
      imagePath = file?.path; // 获取图片路径

      if (imagePath != null) {
        File imageFile = File(imagePath!); // 创建 File 对象
        final tags = await _locationDetectorService.getExifFromImage(imageFile); // 获取 EXIF 数据
        locationInfo = _locationDetectorService.extractLocationFromExif(tags); // 提取位置信息

        // 打印和显示位置信息
        print('Location Info: $locationInfo');
      }

      setState(() => _isPictureTaken = true);
    } catch (e) {
      print('Error taking picture or detecting location: $e');
    }
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }

  _reload() {
    if (mounted) {
      setState(() {
        _isPictureTaken = false;
        locationInfo = 'Location info will appear here'; // 重置位置信息
      });
      _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = CameraHeader("LOCATION ANALYSIS", onBackPressed: _onBackPressed);
    final body = _isInitializing
        ? Center(child: CircularProgressIndicator())
        : _isPictureTaken
            ? Column(
                children: [
                  if (imagePath != null)
                    Image.file(File(imagePath!)), // 显示拍摄的图片
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      locationInfo ?? 'No location info available',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ), // 显示位置信息
                  ),
                ],
              )
            : CameraPreview(_cameraService.cameraController!); // 显示相机预览

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [
          body,
          header,
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !_isPictureTaken
          ? AuthActionButton(
              onPressed: takePictureAndDetectLocation, // 点击按钮后拍照并检测位置
              isLogin: false,
              reload: _reload,
            )
          : null, // 拍照后不再显示按钮
    );
  }
}
