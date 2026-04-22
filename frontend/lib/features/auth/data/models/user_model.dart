class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final DateTime? dateJoined;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    this.dateJoined,
  });

  // Create a User model from a JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImageUrl: json['profile_image_url'],
      dateJoined: json['date_joined'] != null 
          ? DateTime.parse(json['date_joined']) 
          : null,
    );
  }

  // Convert the User model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image_url': profileImageUrl,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }

  // Create a copy of the User model with updated fields
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    DateTime? dateJoined,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }
} 