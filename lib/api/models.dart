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
    this.screens = const {},
    this.isSuperAdmin = false,
    this.staff,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final List<String> roles;
  final Set<String> permissions;

  /// Screen keys from `/me`. Empty when the payload had no `screens` list.
  final Set<String> screens;
  final bool isSuperAdmin;
  final StaffProfile? staff;

  bool can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  factory StaffUser.fromJson(Object? raw) {
    final root = asMap(raw);
    final nested = root['user'] is Map;
    final user = nested ? asMap(root['user']) : root;
    final staff = user['staff'];
    return StaffUser(
      id: toNum(user['id'])?.toInt() ?? 0,
      name: pickString(user, const ['name']) ?? '',
      email: pickString(user, const ['email']),
      phone: pickString(user, const ['phone']),
      roles: _strings(root, user, 'roles', nested: nested),
      permissions: _strings(root, user, 'permissions', nested: nested).toSet(),
      screens: _strings(root, user, 'screens', nested: nested).toSet(),
      isSuperAdmin:
          root['is_super_admin'] == true || user['is_super_admin'] == true,
      staff: staff is Map ? StaffProfile.fromJson(staff) : null,
    );
  }

  Json toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'roles': roles,
    'permissions': permissions.toList(),
    'screens': screens.toList(),
    'is_super_admin': isSuperAdmin,
    'staff': staff?.toJson(),
  };
}

List<String> _strings(
  Json root,
  Json user,
  String key, {
  required bool nested,
}) {
  final top = asList(root[key]);
  final inner = asList(user[key]);
  final source = nested && top.isNotEmpty
      ? top
      : (top.isNotEmpty ? top : inner);
  return [
    for (final item in source)
      if (item is String && item.isNotEmpty) item,
  ];
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
