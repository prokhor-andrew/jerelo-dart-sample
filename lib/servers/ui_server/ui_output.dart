
import 'package:jerelo_sample/app_domain/dto/sign_in_creds.dart';

sealed class UiOutput {
  const UiOutput();
}

final class GetSignInCredsUiOutput extends UiOutput {
  final SignInCreds creds;

  const GetSignInCredsUiOutput(this.creds);
}

final class GetSignOutTriggerUiOutput extends UiOutput {}

final class GetMealsTriggerUiOutput extends UiOutput {}