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
    _locationDetect(); // 启动图像流
    setState(() => _isInitializing = false);
  }

  void _locationDetect() async {
    bool processing = false;
    _cameraService.cameraController!.startImageStream((CameraImage image) async {
      if (processing) return; // 防止过度处理
      processing = true;
      _detectLocationFromImage(image: image); // 添加处理图像的逻辑
      processing = false;
    });
  }

  void _detectLocationFromImage({required CameraImage image}) async {
    // 假设我们只需要处理每帧的第一个图像，避免过度处理
    if (image.planes.isEmpty) return;

    // 获取图像的 YUV 数据
    final bytes = image.planes[0].bytes;

    // 假设我们想通过检查图像的平均颜色来进行一些简单的逻辑判断
    final int pixelCount = bytes.lengthInBytes;
    int sum = 0;

    // 计算 YUV 数据的平均值
    for (int i = 0; i < pixelCount; i++) {
      sum += bytes[i];
    }

    final averageColor = sum ~/ pixelCount; // 计算平均颜色

    // 根据平均颜色做一些逻辑判断
    if (averageColor < 128) {
      print("Detected dark environment."); // 假设暗环境
      // 这里可以进行相应的操作，比如发送位置数据或通知用户等
    } else {
      print("Detected bright environment."); // 假设亮环境
      // 进行其他操作
    }

    // 这里可以根据需要进一步处理图像，例如使用机器学习模型等
  }

  /// 拍照并获取位置信息
  Future<void> takePictureAndDetectLocation() async {
    try {
      // 检查相机是否已经初始化
      if (!_cameraService.cameraController!.value.isInitialized) {
        print("Camera not initialized.");
        return;
      }

      // 确保图像流正在活动
      if (!_cameraService.cameraController!.value.isStreamingImages) {
        print("No image streaming is active.");
        return;
      }

      // 进行拍照
      XFile? file = await _cameraService.takePicture(); 
      imagePath = file?.path;

      if (imagePath != null) {
        File imageFile = File(imagePath!); 
        print('imageFile Info: $imageFile'); 
        final tags = await _locationDetectorService.getExifFromImage(imageFile);
        print('tags Info: $tags'); 
        locationInfo = _locationDetectorService.extractLocationFromExif(tags);

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
