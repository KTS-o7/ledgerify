import 'package:permission_handler/permission_handler.dart';

/// Service for handling SMS permission requests.
///
/// Encapsulates permission logic and provides clear status reporting.
class SmsPermissionService {
  /// Check if SMS permission is currently granted
  Future<bool> isGranted() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Check if SMS permission is permanently denied
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.sms.status;
    return status.isPermanentlyDenied;
  }

  /// Request SMS permission from user
  ///
  /// Returns true if permission was granted, false otherwise.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Open app settings (for when permission is permanently denied)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Get detailed permission status
  Future<SmsPermissionStatus> getStatus() async {
    final status = await Permission.sms.status;

    if (status.isGranted) {
      return SmsPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return SmsPermissionStatus.permanentlyDenied;
    } else if (status.isDenied) {
      return SmsPermissionStatus.denied;
    } else if (status.isRestricted) {
      return SmsPermissionStatus.restricted;
    }

    return SmsPermissionStatus.denied;
  }
}

/// SMS permission status enum for UI consumption
enum SmsPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}
