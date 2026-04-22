import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:logger/logger.dart';

/// Service to handle biometric authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricAccountKey = 'biometric_account';
  
  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      if (kIsWeb) return false; // Not supported on web
      
      // Check if hardware supports biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      // Get available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return canCheckBiometrics && availableBiometrics.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to check biometric availability: $e');
      return false;
    }
  }
  
  /// Get available biometric authentication types
  Future<List<BiometricType>> getAvailableBiometricTypes() async {
    try {
      if (kIsWeb) return []; // Not supported on web
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('Failed to get biometric types: $e');
      return [];
    }
  }
  
  /// Check if biometric authentication is enabled for this account
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      _logger.e('Failed to check if biometric is enabled: $e');
      return false;
    }
  }
  
  /// Check if the current account matches the one registered for biometrics
  Future<bool> isCurrentAccountRegistered(String email) async {
    try {
      final registeredAccount = await _secureStorage.read(key: _biometricAccountKey);
      return registeredAccount == email;
    } catch (e) {
      _logger.e('Failed to check registered account: $e');
      return false;
    }
  }
  
  /// Enable biometric authentication for the current account
  Future<bool> enableBiometric(String email) async {
    try {
      if (!await isBiometricAvailable()) {
        _logger.w('Biometric not available on this device');
        return false;
      }
      
      // Authenticate first to confirm user identity
      final authenticated = await authenticate(
        localizedReason: 'Verify your identity to enable biometric login',
      );
      
      if (!authenticated) {
        _logger.w('User canceled biometric enrollment or authentication failed');
        return false;
      }
      
      // Save biometric settings
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      await _secureStorage.write(key: _biometricAccountKey, value: email);
      
      _logger.i('Biometric authentication enabled for: $email');
      return true;
    } catch (e) {
      _logger.e('Failed to enable biometric: $e');
      return false;
    }
  }
  
  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      // Note: We don't delete the account to remember which account was last used
      _logger.i('Biometric authentication disabled');
      return true;
    } catch (e) {
      _logger.e('Failed to disable biometric: $e');
      return false;
    }
  }
  
  /// Perform biometric authentication
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      if (kIsWeb) {
        _logger.w('Biometric authentication not supported on web');
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        _logger.i('Biometric authentication successful');
      } else {
        _logger.i('Biometric authentication failed or canceled');
      }
      
      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        _logger.w('Biometric authentication not available');
      } else if (e.code == auth_error.notEnrolled) {
        _logger.w('No biometrics enrolled on this device');
      } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        _logger.w('Biometric authentication locked out: ${e.message}');
      } else {
        _logger.e('Biometric authentication error: ${e.message}');
      }
      return false;
    } catch (e) {
      _logger.e('Biometric authentication error: $e');
      return false;
    }
  }
  
  /// Get a user-friendly string for the available biometric type
  Future<String> getBiometricTypeString() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      if (types.isEmpty) return 'None';
      
      return types.fold<String>('', (prev, type) {
        final typeName = _getBiometricTypeName(type);
        return prev.isEmpty ? typeName : '$prev, $typeName';
      });
    } catch (e) {
      return 'Unknown';
    }
  }
  
  /// Convert BiometricType enum to user-friendly string
  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Basic Biometric';
      default:
        return 'Biometric';
    }
  }
}

/// Provider for biometric service
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
}); 