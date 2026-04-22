
class AdminUser {
  final String id;
  final String userName;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final DateTime dateJoined;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final int? postCount;
  final int? commentCount;
  final int? flagCount;
  final DateTime? lastActive;

  AdminUser({
    required this.id,
    required this.userName,
    this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
    required this.dateJoined,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    this.postCount,
    this.commentCount,
    this.flagCount,
    this.lastActive,
  });

  // Getters for compatibility with user_management_page.dart
  String get username => userName;
  String? get fullName => (firstName != null && lastName != null) 
      ? '$firstName $lastName' 
      : (firstName ?? lastName);
  bool? get isAdmin => isStaff || isSuperuser;
  String get dateJoinedString => dateJoined.toIso8601String();
  String? get lastLogin => lastActive?.toIso8601String();

  AdminUser copyWith({
    String? id,
    String? userName,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImage,
    DateTime? dateJoined,
    bool? isActive,
    bool? isStaff,
    bool? isSuperuser,
    int? postCount,
    int? commentCount,
    int? flagCount,
    DateTime? lastActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      dateJoined: dateJoined ?? this.dateJoined,
      isActive: isActive ?? this.isActive,
      isStaff: isStaff ?? this.isStaff,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      postCount: postCount ?? this.postCount,
      commentCount: commentCount ?? this.commentCount,
      flagCount: flagCount ?? this.flagCount,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      userName: json['user_name'] ?? json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImage: json['profile_image'] ?? json['profileImage'],
      dateJoined: DateTime.parse(json['date_joined'] ?? json['dateJoined']),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      postCount: json['post_count'],
      commentCount: json['comment_count'],
      flagCount: json['flag_count'],
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'date_joined': dateJoined.toIso8601String(),
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'post_count': postCount,
      'comment_count': commentCount,
      'flag_count': flagCount,
      'last_active': lastActive?.toIso8601String(),
    };
  }
} 