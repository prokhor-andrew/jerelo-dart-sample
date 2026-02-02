import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/app_domain/dto/auth_user.dart';
import 'package:jerelo_sample/app_domain/dto/config.dart';
import 'package:jerelo_sample/app_domain/dto/sign_in_creds.dart';

final class ApiService {
  final Cont<Config> Function() getConfig;

  final Cont<()> Function(Config config) setConfig;

  final Cont<AuthUser> Function() getAuthUser;

  final Cont<SignInCreds> Function() getSignInCreds;

  final Cont<bool> Function(SignInCreds creds) validateCreds;

  final Cont<LoggedUser> Function(SignInCreds creds) signIn;

  final Cont<()> Function() getSignOutTrigger;

  final Cont<AnonUser> Function() signOut;

  final Cont<()> Function() getMealsTrigger;

  final Cont<List<String>> Function() getMeals;

  final Cont<()> Function(List<String> meals) showMeals;

  const ApiService({
    required this.getConfig,
    required this.setConfig,
    required this.getAuthUser,
    required this.getSignInCreds,
    required this.validateCreds,
    required this.signIn,
    required this.getSignOutTrigger,
    required this.signOut,
    required this.getMealsTrigger,
    required this.getMeals,
    required this.showMeals,
    //
  });
}

extension DomainFlowsExtension on ApiService {
  String _tokenFromLoggedUser(LoggedUser user) {
    return user.token;
  }

  Cont<Never> getMealsFlow() {
    return Cont.fromDeferred(() {
      return getMealsTrigger().then0(getMeals).then(showMeals).then0(getMealsFlow);
    });
  }

  Cont<Never> anonUserAppFlow() {
    return getSignInCreds()
        .thenTap(validateCreds)
        .then(signIn)
        .map(_tokenFromLoggedUser)
        //
        .then(loggedUserAppFlow);
  }

  Cont<Never> loggedUserAppFlow(String token) {
    return getSignOutTrigger().then0(signOut).then0(anonUserAppFlow).raceForWinnerWith(getMealsFlow());
  }
}

Cont<Never> program(ApiService service) {
  return service.getConfig().then(service.setConfig).then0(service.getAuthUser).then((authUser) {
    return switch (authUser) {
      AnonUser() => service.anonUserAppFlow(),
      LoggedUser(token: final token) => service.loggedUserAppFlow(token),
    };
  });
}
