class AppUser {
  const AppUser({required this.username});

  final String username;

  AppUser copyWith({String? username}) {
    return AppUser(username: username ?? this.username);
  }
}
