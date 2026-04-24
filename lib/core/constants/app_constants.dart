class AppConstants {
  AppConstants._();

  static const String appName = 'ClockLy';
  static const String appVersion = '1.0.0';

  // Session
  static const String tokenKey = 'clockly_access_token';
  static const String refreshTokenKey = 'clockly_refresh_token';
  static const String businessIdKey = 'clockly_active_business_id';

  // Legal — override at build time:
  //   --dart-define=CLOCKLY_PRIVACY_URL=https://your-domain.com/privacy
  static const String privacyPolicyUrl = String.fromEnvironment(
    'CLOCKLY_PRIVACY_URL',
    defaultValue: 'https://clockly.app/privacy',
  );
  static const String termsOfServiceUrl = String.fromEnvironment(
    'CLOCKLY_TERMS_URL',
    defaultValue: 'https://clockly.app/terms',
  );

  // Kiosk
  static const int kioskPinLength = 4;
  static const Duration kioskInactivityTimeout = Duration(minutes: 3);
  static const int kioskMaxFailedAttempts = 3;
  static const Duration kioskLockoutDuration = Duration(seconds: 30);

  // Attendance
  static const Duration attendanceRefreshInterval = Duration(seconds: 30);

  // Subscription plans
  static const String planFree = 'free';
  static const String planPro = 'pro';
  static const String planEnterprise = 'enterprise';

  // Roles
  static const String roleSuperadmin = 'superadmin';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleEmployee = 'employee';

  // Ticket status
  static const String ticketPending = 'pending';
  static const String ticketApproved = 'approved';
  static const String ticketRejected = 'rejected';
  static const String ticketReimbursed = 'reimbursed';

  // Attendance status
  static const String attendanceActive = 'active';
  static const String attendanceClosed = 'closed';
  static const String attendanceManualClose = 'manual_close';

  // Pagination
  static const int defaultPageSize = 20;
}
