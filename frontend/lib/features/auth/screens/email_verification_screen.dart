import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailVerificationScreen extends StatefulWidget {
  final String? verificationKey;
  final String? code;
  final String? success;
  final String? error;
  
  const EmailVerificationScreen({
    super.key, 
    this.verificationKey, 
    this.code,
    this.success,
    this.error,
  });

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Check for direct success/error parameters from URL (redirect case)
    if (widget.success != null) {
      setState(() {
        _isLoading = false;
        _isVerified = true;
      });
      return;
    }
    
    if (widget.error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.error;
      });
      return;
    }
    
    // Only make the verification API call if we have key and code but no success/error indicator
    if (widget.verificationKey != null && widget.code != null) {
      _verifyEmail();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid verification link';
      });
    }
  }
  
  Future<void> _verifyEmail() async {
    if (widget.verificationKey == null || widget.code == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid verification link';
      });
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/verify-email/?key=${widget.verificationKey}&code=${widget.code}'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _isVerified = true;
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _isLoading = false;
          _errorMessage = errorData['error'] ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred while verifying your email';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Verifying your email...', style: theme.textTheme.bodyLarge),
              ] else if (_isVerified) ...[
                Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                Text(
                  'Email Verified Successfully!',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your email has been verified. You can now log in to your account.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onPressed: () => context.go('/login'),
                  text: 'Go to Login',
                ),
              ] else ...[
                Icon(Icons.error, color: Colors.red, size: 80),
                const SizedBox(height: 24),
                Text(
                  'Verification Failed',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to verify your email. The link may have expired.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onPressed: () => context.go('/login'),
                  text: 'Go to Login',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 