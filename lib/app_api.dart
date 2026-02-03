import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/app_domain/api_service.dart';
import 'package:jerelo_sample/app_domain/dto/auth_user.dart';
import 'package:jerelo_sample/app_domain/dto/config.dart';
import 'package:jerelo_sample/app_domain/dto/theme_config.dart';
import 'package:jerelo_sample/servers/http_server/http_server.dart';
import 'package:jerelo_sample/servers/store_server/store_server.dart';
import 'package:jerelo_sample/servers/ui_server/ui_input.dart';
import 'package:jerelo_sample/servers/ui_server/ui_output.dart';
import 'package:jerelo_sample/servers/ui_server/ui_server.dart';
import 'package:jerelo_sample/utils/utils.dart';

Cont<ApiService> getAppApi() {
  return Cont.fromDeferred(() {
    final storeAndHttp = Cont.both(
      getStoreServer(),
      getHttpServer(),
      (store, http) => (store, http),
      policy: ContPolicy.mergeWhenAll((errors1, errors2) => errors1 + errors2),
      //
    );

    final servers = getUiServer().zip0(() => storeAndHttp, (ui, servers) => (ui, servers));

    return servers.then((servers) {
      final (ui, (store, http)) = servers;

      return Cont.of(
        ApiService(
          getConfig: () {
            return fromFutureComp(() async {
              final isLightTheme = store.getBool('is_light_theme') ?? true;
              return isLightTheme ? const Config(ThemeConfig.light) : const Config(ThemeConfig.dark);
            });
          },
          setConfig: (config) {
            return ui.enqueue(SetConfigUiInput(config.theme));
          },
          getAuthUser: () {
            return fromFutureComp(() async {
              final token = store.getString("user_token");

              if (token == null) {
                return AnonUser();
              }

              return LoggedUser(token);
            });
          },
          getSignInCreds: () {
            return ui.enqueue(GetSignInCredsUiInput()).then0(() {
              return ui.dequeue
                  .until((output) {
                    return output is GetSignInCredsUiOutput;
                  })
                  .map((output) {
                    return (output as GetSignInCredsUiOutput).creds;
                  });
            });
          },
          validateCreds: (creds) {
            return Cont.fromDeferred(() {
              return Cont.of(creds.email.isNotEmpty && creds.password.isNotEmpty);
            });
          },
          signIn: (creds) {
            return fromFutureComp(() async {
              final token = creds.email + creds.password;
              await store.setString("user_token", token);
              return LoggedUser(token);
            });
          },
          getSignOutTrigger: () {
            return ui
                .enqueue(GetSignOutTriggerUiInput())
                .then0(() {
                  return ui.dequeue.until((output) {
                    return output is GetSignOutTriggerUiOutput;
                  });
                })
                .mapTo(());
          },
          signOut: () {
            return fromFutureComp(() async {
              await store.remove("user_token");
              return AnonUser();
            });
          },
          getMealsTrigger: () {
            return ui
                .enqueue(GetMealsTriggerUiInput())
                .then0(() {
                  return ui.dequeue.until((output) {
                    return output is GetMealsTriggerUiOutput;
                  });
                })
                .mapTo(());
          },
          getMeals: () {
            return fromFutureComp(() async {
              final result = await http.get('search.php', queryParameters: {'s': 'Arrabiata'});

              final List<dynamic> list = result.data['meals'];

              final meals = list.map((item) {
                return item['strMeal'] as String;
              }).toList();

              return meals;
            }).elseThen((errors) {
              return Cont.of(<String>[]);
            });
          },
          showMeals: (meals) {
            return ui.enqueue(ShowMealsUiInput(meals));
          },
        ),
      );
    });
  });
}
