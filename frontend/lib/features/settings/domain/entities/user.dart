class User {
  String username;
  String first_name;
  String last_name;
  String? profile_photo;
  String? new_password;
  String? confirm_password;
  String email;

  User({
    required this.username,
    required this.first_name,
    required this.last_name,
    this.profile_photo,
    this.new_password,
    this.confirm_password,
    required this.email,
  });

  @override
  String toString() {
    return 'User(username: $username, first_name: $first_name, last_name: $last_name, profile_photo: $profile_photo, email: $email)';
  }
}
