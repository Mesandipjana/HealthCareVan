import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LocalSelfieStore {
  LocalSelfieStore._();

  static Future<String> save(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final selfieDir = Directory('${directory.path}/attendance_selfies');
    await selfieDir.create(recursive: true);

    final extension = image.name.split('.').lastOrNull ?? 'jpg';
    final fileName =
        'attendance_selfie_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final targetPath = '${selfieDir.path}/$fileName';
    final savedFile = await File(image.path).copy(targetPath);
    return savedFile.path;
  }
}
