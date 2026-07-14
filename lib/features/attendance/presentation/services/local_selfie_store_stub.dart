import 'package:image_picker/image_picker.dart';

class LocalSelfieStore {
  LocalSelfieStore._();

  static Future<String> save(XFile image) async {
    return image.path;
  }
}
