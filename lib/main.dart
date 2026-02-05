import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/app_api.dart';
import 'package:jerelo_sample/api_service.dart';

void main() {
  getAppApi().injectInto(program()).trap((), (errors) {
    print('App Errors: ${errors.length}');
  });
}
