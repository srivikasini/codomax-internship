/// Non-web fallback implementation for browser notifications, chimes, and mailto launch.
bool get isBrowserAlertSupported => false;

String get browserNotificationPermission => 'unsupported';

Future<String> requestBrowserNotificationPermission() async => 'unsupported';

Future<void> triggerBrowserAlert({
  required String title,
  required String body,
  bool playSound = true,
}) async {}

Future<bool> openEmailDraft({
  required String toEmail,
  required String subject,
  required String body,
}) async {
  return false;
}
