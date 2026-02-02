sealed class AuthUser {
  const AuthUser();
}

final class AnonUser extends AuthUser {
  const AnonUser();
}

final class LoggedUser extends AuthUser {
  final String token;

  const LoggedUser(this.token);
}
