import '../../domain/entities/user.dart';

class UserModel extends User {
  final String username;
  final String first_name;
  final String last_name;
  final String? profile_photo;
  final String? new_password;
  final String? confirm_password;
  final String email;

  UserModel({
    required this.username,
    required this.first_name,
    required this.last_name,
    this.profile_photo,
    this.new_password,
    this.confirm_password,
    required this.email,
  }) : super(
         username: username,
         first_name: first_name,
         last_name: last_name,
         profile_photo: profile_photo,
         new_password: new_password,
         confirm_password: confirm_password,
         email: email,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    username: json['user_name'] as String,
    first_name: json['first_name'] as String,
    last_name: json['last_name'] as String,
    profile_photo: json['profile_image'] as String?,
    email: json['email'] as String,
  );

  factory UserModel.fromEntity(User user) => UserModel(
    username: user.username,
    first_name: user.first_name,
    last_name: user.last_name,
    profile_photo: user.profile_photo,
    new_password: user.new_password,
    confirm_password: user.confirm_password,
    email: user.email,
  );

  Map<String, dynamic> toJson() => {
    'user_name': username,
    'first_name': first_name,
    'last_name': last_name,
    'profile_image': profile_photo,
    if (new_password != null && new_password!.isNotEmpty) 'new_password': new_password,
    if (confirm_password != null && confirm_password!.isNotEmpty) 'confirm_password': confirm_password,
  };
}
