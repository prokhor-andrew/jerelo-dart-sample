import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/app_domain/api_service.dart';
import 'package:jerelo_sample/servers/http_server/http_server.dart';
import 'package:jerelo_sample/servers/store_server/store_server.dart';
import 'package:jerelo_sample/servers/ui_server/ui_server.dart';

Cont<(), ApiService> getAppApi() {
  return Cont.fromDeferred(() {
    final storeAndHttp = Cont.both(
      getStoreServer(),
      getHttpServer(),
      (store, http) => (store, http),
      policy: ContPolicy.mergeWhenAll((errors1, errors2) => errors1 + errors2),
      //
    );

    final servers = getUiServer<()>().thenZip0(() => storeAndHttp, (ui, servers) => (ui, servers));

    return servers.thenDo((servers) {
      final (ui, (store, http)) = servers;

      return Cont.of(ApiService(http: http, ui: ui, store: store));
    });
  });
}
