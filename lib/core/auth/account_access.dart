/// Public account intent is not an authorization claim. The server must
/// independently approve host applications and assign staff permissions.
enum AccountIntent { tourist, experienceHost }

enum HostApplicationStatus {
  notApplied,
  pendingReview,
  approved,
  rejected,
  suspended,
}

class AccountAccess {
  const AccountAccess({required this.hostStatus, required this.isStaff});

  final HostApplicationStatus hostStatus;

  /// Must come from trusted server-side role data, never public user metadata.
  final bool isStaff;

  bool get canBrowseAsTourist => true;
  bool get canPublishExperiences =>
      hostStatus == HostApplicationStatus.approved;
  bool get canOpenAdminTools => isStaff;
}
