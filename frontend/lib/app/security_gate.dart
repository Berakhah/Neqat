import 'package:flutter/material.dart';
import 'package:frontend/services/device_security_service.dart';

class SecurityGate extends StatefulWidget {
  final Widget child;
  /// Set to true to block usage on insecure devices, false to only show a warning.
  final bool blockInsecureDevice;
  const SecurityGate({required this.child, this.blockInsecureDevice = false, super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  bool? _insecure;
  bool _warningDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final insecure = await DeviceSecurityService.isDeviceInsecure();
    setState(() {
      _insecure = insecure;
      _warningDismissed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always wrap with Directionality to avoid errors before MaterialApp
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) {
          if (_insecure == null) {
            // Loading state
            return const Center(child: CircularProgressIndicator());
          }

          if (_insecure! && widget.blockInsecureDevice) {
            // Blocking mode
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'This device is rooted, jailbroken, or running in an emulator.\nFor your security, the app cannot be used.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _checkSecurity,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Warning-only mode: show a dismissible banner, but allow app usage
          return Stack(
            children: [
              widget.child,
              if (_insecure! && !_warningDismissed)
                Container(
                  width: double.infinity,
                  color: Colors.yellow[800],
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.black),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Warning: This device is rooted, jailbroken, or running in an emulator.',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Use a simple TextButton for dismiss, not IconButton/Tooltip
                      TextButton(
                        onPressed: () => setState(() => _warningDismissed = true),
                        child: const Text('Dismiss', style: TextStyle(color: Colors.black)),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 