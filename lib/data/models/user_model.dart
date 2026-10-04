enum UserRole {
  residential,
  facilityManager,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.residential:
        return 'Residential User';
      case UserRole.facilityManager:
        return 'Facility Manager';
      case UserRole.admin:
        return 'System Admin';
    }
  }

  String get code {
    switch (this) {
      case UserRole.residential:
        return 'RESIDENTIAL';
      case UserRole.facilityManager:
        return 'FACILITY_MANAGER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }
}

class UserModel {
  final String userID;
  final String name;
  final String email;
  final UserRole role;
  final String organizationID;

  UserModel({
    required this.userID,
    required this.name,
    required this.email,
    required this.role,
    required this.organizationID,
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'role': role.code,
      'organizationID': organizationID,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    UserRole parsedRole = UserRole.residential;
    final r = map['role'] as String?;
    if (r == 'FACILITY_MANAGER') {
      parsedRole = UserRole.facilityManager;
    } else if (r == 'ADMIN') {
      parsedRole = UserRole.admin;
    }

    return UserModel(
      userID: map['userID'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: parsedRole,
      organizationID: map['organizationID'] ?? '',
    );
  }
}
