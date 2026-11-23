/// Staff sign-in id: an email, or one user's mobile (`017…`, `+880…`, dashes ok).
bool isStaffLoginId(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return false;
  if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return true;
  final mobile = value.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^(?:\+?880|0)1[3-9]\d{8}$').hasMatch(mobile);
}
