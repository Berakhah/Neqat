import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/data/services/biometric_service.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

class BiometricTestScreen extends ConsumerStatefulWidget {
  const BiometricTestScreen({super.key});

  @override
  ConsumerState<BiometricTestScreen> createState() => _BiometricTestScreenState();
}

class _BiometricTestScreenState extends ConsumerState<BiometricTestScreen> {
  final Logger _logger = Logger();
  bool _isAvailable = false;
  bool _isEnabled = false;
  String _biometricType = 'Unknown';
  String _status = 'Checking biometric capabilities...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Check if biometric authentication is available
      final isAvailable = await biometricService.isBiometricAvailable();
      final isEnabled = await biometricService.isBiometricEnabled();
      final biometricType = await biometricService.getBiometricTypeString();

      setState(() {
        _isAvailable = isAvailable;
        _isEnabled = isEnabled;
        _biometricType = biometricType;
        _status = isAvailable 
            ? 'Biometric authentication is available' 
            : 'Biometric authentication is not available';
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Failed to check biometrics: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _status = 'Authenticating...';
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);
      
      final result = await biometricService.authenticate(
        localizedReason: 'Authenticate to test biometric login',
      );

      setState(() {
        _status = result 
            ? 'Authentication successful' 
            : 'Authentication failed or canceled';
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Authentication error: $e');
      setState(() {
        _status = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometrics() async {
    setState(() {
      _isLoading = true;
      _status = _isEnabled ? 'Disabling biometrics...' : 'Enabling biometrics...';
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);
      
      if (_isEnabled) {
        // Disable biometrics
        await biometricService.disableBiometric();
        setState(() {
          _isEnabled = false;
          _status = 'Biometric authentication disabled';
          _isLoading = false;
        });
      } else {
        // Enable biometrics - use a test email for this screen
        final success = await biometricService.enableBiometric('test@example.com');
        setState(() {
          _isEnabled = success;
          _status = success 
              ? 'Biometric authentication enabled' 
              : 'Failed to enable biometric authentication';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Toggle biometrics error: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkBiometrics,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biometric Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow('Available', _isAvailable),
                    _buildStatusRow('Enabled', _isEnabled),
                    _buildStatusRow('Type', _biometricType, isBoolean: false),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isAvailable) ...[
                    ElevatedButton(
                      onPressed: _authenticate,
                      child: const Text('Test Authentication'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _toggleBiometrics,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEnabled 
                            ? Colors.redAccent 
                            : Theme.of(context).primaryColor,
                      ),
                      child: Text(_isEnabled ? 'Disable Biometrics' : 'Enable Biometrics'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value, {bool isBoolean = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isBoolean)
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
            )
          else
            Text(value.toString()),
        ],
      ),
    );
  }
} 