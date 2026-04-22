import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:frontend/presentation/widgets/input_field.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:frontend/features/auth/data/datasources/auth_api_service.dart';
import 'package:frontend/app/main.dart';
import 'package:frontend/l10n/app_localizations.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;
  
  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;
  bool _showVerificationStep = false;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    // If initialToken is provided, pre-fill the code field and show verification step
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _codeController.text = widget.initialToken!;
      _showVerificationStep = true;
    }
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  bool _validatePassword(String password) {
    // Require at least 8 characters with at least one letter and one number
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Za-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = l10n.emailEmptyError;
      });
      return;
    }

    if (!_validateEmail(email)) {
      setState(() {
        _errorMessage = l10n.invalidEmailError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get the repository from Riverpod
      final authRepository = ref.read(authRepositoryProvider);
      _logger.i("Requesting password reset for email: $email");

      final result = await authRepository.requestPasswordReset(
        email: email,
      );

      _logger.d("Password reset request response: $result");

      if (!result.containsKey('error')) {
        _logger.i("Password reset instructions sent successfully");
        setState(() {
          _successMessage = result['message'] ?? l10n.resetInstructionsSent;
          _showVerificationStep = true;
          _isLoading = false;
        });
      } else {
        _logger.w("Password reset request failed: ${result['message']}");
        setState(() {
          _errorMessage = result['message'] ?? l10n.resetEmailFailed;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e("Password reset request error", error: e);
      setState(() {
        _errorMessage = l10n.unexpectedError;
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = l10n.emptyFieldsError;
      });
      return;
    }

    if (!_validatePassword(newPassword)) {
      setState(() {
        _errorMessage = l10n.passwordRequirementError;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = l10n.passwordMismatchError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get the repository from Riverpod
      final authRepository = ref.read(authRepositoryProvider);
      _logger.i("Resetting password with verification code");

      final result = await authRepository.resetPassword(
        verificationCode: code,
        newPassword: newPassword,
      );

      _logger.d("Password reset response: $result");

      if (!result.containsKey('error')) {
        _logger.i("Password reset successful");
        
        // Check if we received authentication tokens with the response
        if (result.containsKey('access') && result.containsKey('refresh')) {
          _logger.i("User automatically authenticated after password reset");
          // Success with auto-login - navigate directly to home
          if (mounted) {
            // Navigate to home screen
            context.go('/home');
          }
        } else {
          // If no tokens, just show success dialog
          if (mounted) {
            _showSuccessAndNavigate();
          }
        }
      } else {
        _logger.w("Password reset failed: ${result['message']}");
        setState(() {
          _errorMessage = result['message'] ?? l10n.resetPasswordFailed;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e("Password reset error", error: e);
      setState(() {
        _errorMessage = l10n.unexpectedError;
        _isLoading = false;
      });
    }
  }

  void _showSuccessAndNavigate() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.successTitle),
          content: Text(l10n.passwordResetSuccess),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.replace('/login');
              },
              child: Text(l10n.loginButton),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardOpen = viewInsets.bottom > 0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button - always visible
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                      onPressed: () => context.replace('/login'),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  
                  // Hide title when keyboard is open on small screens
                  if (!keyboardOpen || size.height > 650) ...[
                    const SizedBox(height: 16),
                    Text(
                      _showVerificationStep 
                          ? l10n.resetPasswordTitle
                          : l10n.forgotPasswordTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showVerificationStep
                          ? l10n.verificationCodePrompt
                          : l10n.emailResetPrompt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(height: keyboardOpen ? 16 : 32),
                  ],
                  
                  // Error and success messages
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  
                  // Show the appropriate step
                  _showVerificationStep ? _buildVerificationStep() : _buildRequestStep(),
                  
                  // Only show extra content when keyboard is closed
                  if (!keyboardOpen) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: TextButton(
                        onPressed: () => context.replace('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                        child: Text(l10n.rememberPasswordLink),
                      ),
                    ),
                  ],
                  
                  // Extra space at bottom
                  SizedBox(height: keyboardOpen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Method to build the request password step UI
  Widget _buildRequestStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomInputField(
          controller: _emailController,
          hintText: l10n.emailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onEditingComplete: _requestPasswordReset,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: l10n.sendResetInstructionsButton,
          onPressed: _requestPasswordReset,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // Method to build the verification step UI
  Widget _buildVerificationStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomInputField(
          controller: _codeController,
          hintText: l10n.verificationCodeHint,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        CustomInputField(
          controller: _newPasswordController,
          hintText: l10n.newPasswordHint,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        CustomInputField(
          controller: _confirmPasswordController,
          hintText: l10n.confirmNewPasswordHint,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onEditingComplete: _resetPassword,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: l10n.resetPasswordButton,
          onPressed: _resetPassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}