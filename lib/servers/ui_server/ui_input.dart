import 'package:jerelo_sample/app_domain/dto/theme_config.dart';

sealed class UiInput {
  const UiInput();
}

final class SetConfigUiInput extends UiInput {
  final ThemeConfig config;

  const SetConfigUiInput(this.config);
}

final class GetSignInCredsUiInput extends UiInput {
  const GetSignInCredsUiInput();
}

final class GetSignOutTriggerUiInput extends UiInput {
  const GetSignOutTriggerUiInput();
}

final class GetMealsTriggerUiInput extends UiInput {
  const GetMealsTriggerUiInput();
}

final class ShowMealsUiInput extends UiInput {
  final List<String> meals;

  const ShowMealsUiInput(this.meals);
}
