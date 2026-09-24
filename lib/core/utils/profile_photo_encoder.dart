import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List encodeProfileJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('تعذر قراءة الصورة. استخدم صورة JPG أو PNG واضحة.');
  }

  var image = decoded;
  const maxWidth = 1200;
  if (image.width > maxWidth) {
    image = img.copyResize(
      image,
      width: maxWidth,
      interpolation: img.Interpolation.linear,
    );
  }

  final jpeg = img.encodeJpg(image, quality: 85);
  if (jpeg.isEmpty) {
    throw Exception('تعذر تجهيز الصورة للرفع.');
  }
  return Uint8List.fromList(jpeg);
}
