import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Cont<SharedPreferences> getStoreServer() {
  return fromFutureComp(() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  });
}
