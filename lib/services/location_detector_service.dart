
import 'dart:io';
import 'package:exif/exif.dart';

class LocationDetectorService {
  String location = "未找到位置信息";

  // 获取图片的 Exif 数据
  Future<Map<String, IfdTag>> getExifFromImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final tags = await readExifFromBytes(bytes);
    return tags;
  }

  // 从 Exif 数据中提取位置信息
  String extractLocationFromExif(Map<String, IfdTag> tags) {
    // 检查 GPS 标签
    if (tags.containsKey('GPSLatitude') && tags.containsKey('GPSLongitude')) {
      var latValues = tags['GPSLatitude']?.values.toList().cast<double>();
      var lonValues = tags['GPSLongitude']?.values.toList().cast<double>();
      var latRef = tags['GPSLatitudeRef']?.printable;
      var lonRef = tags['GPSLongitudeRef']?.printable;

      if (latValues != null && lonValues != null && latRef != null && lonRef != null) {
        double latitude = _convertToDegrees(latValues);
        double longitude = _convertToDegrees(lonValues);

        if (latRef == "S") latitude = -latitude;
        if (lonRef == "W") longitude = -longitude;
        return '纬度: $latitude, 经度: $longitude';
      } else {
        return "未找到 GPS 信息";
      }
    } else {
      return "未找到 GPS 信息";
    }
  }

  // 转换经纬度格式
  double _convertToDegrees(List values) {
    return values[0] + (values[1] / 60) + (values[2] / 3600);
  }
}
