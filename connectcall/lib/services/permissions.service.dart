import 'package:permission_handler/permission_handler.dart';

/// Service responsible for handling audio (microphone) and video (camera) permissions.
class PermissionsService {
  Future<bool> requestAudioPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return true;
      }
      final requestStatus = await Permission.microphone.request();
      return requestStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Checks if camera permission is granted. If not, requests it.
  Future<bool> requestVideoPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        return true;
      }
      final requestStatus = await Permission.camera.request();
      return requestStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Convenience alias for [requestAudioPermission].
  Future<bool> requestMicrophonePermission() => requestAudioPermission();

  /// Convenience alias for [requestVideoPermission].
  Future<bool> requestCameraPermission() => requestVideoPermission();

  /// Checks whether audio (microphone) permission is currently granted without prompting.
  Future<bool> hasAudioPermission() async {
    return Permission.microphone.isGranted;
  }

  /// Checks whether video (camera) permission is currently granted without prompting.
  Future<bool> hasVideoPermission() async {
    return Permission.camera.isGranted;
  }
}

/// Alias for [PermissionsService] to support singular naming conventions.
typedef PermissionService = PermissionsService;
