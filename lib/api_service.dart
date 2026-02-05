import 'package:dio/dio.dart';
import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/app_domain/dto/auth_user.dart';
import 'package:jerelo_sample/app_domain/dto/config.dart';
import 'package:jerelo_sample/app_domain/dto/sign_in_creds.dart';
import 'package:jerelo_sample/app_domain/dto/theme_config.dart';
import 'package:jerelo_sample/servers/ui_server/ui_input.dart';
import 'package:jerelo_sample/servers/ui_server/ui_output.dart';
import 'package:jerelo_sample/servers/ui_server/ui_server.dart';
import 'package:jerelo_sample/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class ApiService {
  final Dio http;
  final Bridge<UiInput, UiOutput> ui;
  final SharedPreferences store;

  const ApiService({
    required this.http,
    required this.ui,
    required this.store,
    //
  });
}

Cont<ApiService, Config> getConfig() {
  return Cont.ask<ApiService>().map((service) => service.store).thenDo((store) {
    return fromFutureComp(
      (runtime) async {
        final isLightTheme = store.getBool('is_light_theme') ?? true;
        return isLightTheme ? const Config(ThemeConfig.light) : const Config(ThemeConfig.dark);
      },
      (error, st) {
        return const Config(ThemeConfig.light);
      },
    );
  });
}

Cont<ApiService, ()> setConfig(Config config) {
  return Cont.ask<ApiService>().map((service) => service.ui).thenDo((ui) {
    return ui.enqueue(SetConfigUiInput(config.theme));
  });
}

Cont<ApiService, AuthUser> getAuthUser() {
  return Cont.ask<ApiService>().map((service) => service.store).thenDo((store) {
    return fromFutureComp(
      (runtime) async {
        final token = store.getString("user_token");

        if (token == null) {
          return AnonUser();
        }

        return LoggedUser(token);
      },
      (error, st) {
        return AnonUser();
      },
    );
  });
}

Cont<ApiService, SignInCreds> getSignInCreds() {
  return Cont.ask<ApiService>().map((service) => service.ui).thenDo((ui) {
    return ui.enqueue<ApiService>(GetSignInCredsUiInput()).thenDo0(() {
      return ui
          .dequeue<ApiService>()
          .until((output) {
            return output is GetSignInCredsUiOutput;
          })
          .map((output) {
            return (output as GetSignInCredsUiOutput).creds;
          });
    });
  });
}

Cont<ApiService, bool> validateCreds(SignInCreds creds) {
  return Cont.fromDeferred(() {
    return Cont.of(creds.email.isNotEmpty && creds.password.isNotEmpty);
  });
}

Cont<ApiService, LoggedUser> signIn(SignInCreds creds) {
  return Cont.ask<ApiService>().map((service) => service.store).thenDo((store) {
    return fromFutureComp(
      (runtime) async {
        final token = creds.email + creds.password;
        await store.setString("user_token", token);
        return LoggedUser(token);
      },
      (error, st) {
        throw "Not Logged";
      },
    );
  });
}

Cont<ApiService, ()> getSignOutTrigger() {
  return Cont.ask<ApiService>().map((service) => service.ui).thenDo((ui) {
    return ui
        .enqueue<ApiService>(GetSignOutTriggerUiInput())
        .thenDo0(() {
          return ui.dequeue<ApiService>().until((output) {
            return output is GetSignOutTriggerUiOutput;
          });
        })
        .as(());
  });
}

Cont<ApiService, AnonUser> signOut() {
  return Cont.ask<ApiService>().map((service) => service.store).thenDo((store) {
    return fromFutureComp(
      (runtime) async {
        await store.remove("user_token");
        return AnonUser();
      },
      (error, st) {
        return AnonUser();
      },
    );
  });
}

Cont<ApiService, ()> getMealsTrigger() {
  return Cont.ask<ApiService>().map((service) => service.ui).thenDo((ui) {
    return ui
        .enqueue<ApiService>(GetMealsTriggerUiInput())
        .thenDo0(() {
          return ui.dequeue<ApiService>().until((output) {
            return output is GetMealsTriggerUiOutput;
          });
        })
        .as(());
  });
}

Cont<ApiService, List<String>> getMeals() {
  return Cont.ask<ApiService>().thenDo((service) {
    return fromFutureComp(
      (runtime) async {
        final result = await service.http.get('search.php', queryParameters: {'s': 'Arrabiata'});

        final List<dynamic> list = result.data['meals'];

        final meals = list.map((item) {
          return item['strMeal'] as String;
        }).toList();

        return meals;
      },
      (error, st) {
        return <String>[];
      },
    );
  });
}

Cont<ApiService, ()> showMeals(List<String> meals) {
  return Cont.ask<ApiService>().thenDo((service) {
    return service.ui.enqueue(ShowMealsUiInput(meals));
  });
}

Cont<ApiService, Never> getMealsFlow() {
  return getMealsTrigger().thenDo0(getMeals).thenDo(showMeals).thenDo0(getMealsFlow);
}

String _tokenFromLoggedUser(LoggedUser user) {
  return user.token;
}

Cont<ApiService, Never> anonUserAppFlow() {
  return getSignInCreds()
      .thenTap(validateCreds)
      .thenDo(signIn)
      .map(_tokenFromLoggedUser)
      //
      .thenDo(loggedUserAppFlow);
}

Cont<ApiService, Never> loggedUserAppFlow(String token) {
  return getSignOutTrigger().thenDo0(signOut).or(
    getMealsFlow(),
    mergeLists,
    policy: ContPolicy.quitFast(),
    //
  ).thenDo0(anonUserAppFlow);
}

Cont<ApiService, Never> program() {
  return getConfig().thenDo(setConfig).thenDo0(getAuthUser).thenDo((authUser) {
    return switch (authUser) {
      AnonUser() => anonUserAppFlow(),
      LoggedUser(token: final token) => loggedUserAppFlow(token),
    };
  });
}
