import 'json.dart';

/// The signed-in ERP user (`user` in `/me` and login). Display only: the ERP
/// checks every permission again on every call.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.roles = const [],
    this.permissions = const {},
    this.isSuperAdmin = false,
    this.staff,
    this.screens = const [],
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final List<String> roles;
  final Set<String> permissions;
  final bool isSuperAdmin;
  final StaffProfile? staff;

  /// Home buttons the ERP lists for this login (`/me` → `screens`).
  final List<String> screens;

  bool can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  bool canAny(List<String> list) => list.any(can);

  bool hasRole(String role) => roles.contains(role);

  factory StaffUser.fromJson(Object? raw) {
    final root = asMap(raw);
    final user = root['user'] is Map ? asMap(root['user']) : root;
    final staff = user['staff'];
    return StaffUser(
      id: toNum(user['id'])?.toInt() ?? 0,
      name: pickString(user, const ['name']) ?? '',
      email: pickString(user, const ['email']),
      phone: pickString(user, const ['phone']),
      roles: [
        for (final r in asList(user['roles']))
          if (r is String && r.isNotEmpty) r,
      ],
      permissions: {
        for (final p in asList(user['permissions']))
          if (p is String && p.isNotEmpty) p,
      },
      isSuperAdmin: user['is_super_admin'] == true,
      staff: staff is Map ? StaffProfile.fromJson(staff) : null,
      screens: [
        for (final s in asList(user['screens'] ?? root['screens']))
          if (s is String && s.isNotEmpty) s,
      ],
    );
  }

  Json toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'roles': roles,
    'permissions': permissions.toList(),
    'is_super_admin': isSuperAdmin,
    'staff': staff?.toJson(),
    'screens': screens,
  };
}

class StaffProfile {
  const StaffProfile({
    this.id,
    this.code,
    this.name,
    this.designation,
    this.department,
    this.mobile,
  });

  final int? id;
  final String? code;
  final String? name;
  final String? designation;
  final String? department;
  final String? mobile;

  factory StaffProfile.fromJson(Object? raw) {
    final m = asMap(raw);
    return StaffProfile(
      id: toNum(m['id'])?.toInt(),
      code: pickString(m, const ['code', 'staff_code']),
      name: pickString(m, const ['name']),
      designation: pickString(m, const ['designation']),
      department: pickString(m, const ['department']),
      mobile: pickString(m, const ['mobile']),
    );
  }

  Json toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'designation': designation,
    'department': department,
    'mobile': mobile,
  };
}

/// What `POST /auth/login` (or `/auth/two-factor`) answered.
sealed class LoginOutcome {
  const LoginOutcome();
}

class SignedIn extends LoginOutcome {
  const SignedIn(this.token, this.user);
  final String token;
  final StaffUser user;
}

/// The user has 2FA on: send the code with [challenge] to finish.
class TwoFactorNeeded extends LoginOutcome {
  const TwoFactorNeeded({
    required this.challenge,
    required this.channel,
    this.message,
  });
  final String challenge;

  /// `totp`, `sms` or `telegram`.
  final String channel;
  final String? message;
}
