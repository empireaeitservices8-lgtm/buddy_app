enum UserRole {
  user,
  agent,
  caller;

  bool get isUser => this == UserRole.user;
  bool get isAgent => this == UserRole.agent;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.agent:
        return 'Agent';
      case UserRole.caller:
        throw UnimplementedError();
    }
  }

  String get badgeName {
    switch (this) {
      case UserRole.user:
        return 'CLIENT / MEMBER';
      case UserRole.agent:
        return 'SERVICE PROVIDER';
      case UserRole.caller:
        throw UnimplementedError();
    }
  }

  String get description {
    switch (this) {
      case UserRole.user:
        return 'Find buddies, connect with people, make calls, and explore.';
      case UserRole.agent:
        return 'Log in with username & password to manage calls and assist users.';
      case UserRole.caller:
        throw UnimplementedError();
    }
  }
}
