import 'package:dio/dio.dart';
import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/utils/utils.dart';

Cont<Dio> getHttpServer() {
  return Cont.fromDeferred(() {
    const String baseUrl = "https://www.themealdb.com/api/json/v1/1/";
    final Dio client = Dio(BaseOptions(baseUrl: baseUrl));

    return Cont.of(client);
  }).subscribeOnDelayed();
}
