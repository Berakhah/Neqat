import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/features/auth/presentation/style/auth_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? resetKey;
  final String? code;
  final String? token;

  const ResetPasswordScreen({
    super.key, 
    this.token,
    this.resetKey,
    this.code,
  });

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isResetRequested = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;
  bool _isPasswordValid = false;
  bool _hasMinLength = false;
  bool _hasLetters = false;
  bool _hasNumbers = false;
  bool _doPasswordsMatch = false;

  @override
  void initState() {
    super.initState();
    
    // Check if we have token or Keycloak reset parameters
    _checkResetParameters();
    
    // Add listeners for password validation
    _newPasswordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }
  
  void _validatePassword() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasLetters = RegExp(r'[A-Za-z]').hasMatch(password);
      _hasNumbers = RegExp(r'[0-9]').hasMatch(password);
      _isPasswordValid = _hasMinLength && _hasLetters && _hasNumbers;
    });
  }
  
  void _validatePasswordMatch() {
    setState(() {
      _doPasswordsMatch = _newPasswordController.text == _confirmPasswordController.text;
    });
  }
  
  void _checkResetParameters() {
    // Check if we have a direct token (legacy method)
    if (widget.token != null && widget.token!.isNotEmpty) {
      _codeController.text = widget.token!;
      setState(() {
        _isResetRequested = true;
      });
      return;
    }
    
    // Check if we have Keycloak reset parameters (key and code)
    if (widget.resetKey != null && widget.code != null) {
      // Combine them as our code for now - backend handles the translation
      _codeController.text = "${widget.resetKey}:${widget.code}";
      setState(() {
        _isResetRequested = true;
      });
      return;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = l10n.emptyFieldsError;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authProvider.notifier).requestPasswordReset(email);
      final authState = ref.read(authProvider);
      
      if (authState.errorMessage != null) {
        setState(() {
          _errorMessage = authState.errorMessage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isResetRequested = true;
          _successMessage = l10n.resetInstructionsSent;
          _isLoading = false;
        });
        
        // If we're already in reset mode, show a snackbar to inform the user
        if (_isResetRequested) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.resetInstructionsSent))
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.unexpectedError}: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = l10n.emptyFieldsError;
      });
      return;
    }
    
    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = l10n.passwordMismatchError;
      });
      return;
    }
    
    if (!_isPasswordValid) {
      setState(() {
        _errorMessage = l10n.passwordRequirementError;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authProvider.notifier).resetPassword(code, newPassword);
      final authState = ref.read(authProvider);
      
      if (authState.errorMessage != null) {
        setState(() {
          _errorMessage = authState.errorMessage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _successMessage = l10n.passwordResetSuccess;
          _isLoading = false;
        });
        
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_successMessage!))
        );
        
        // Delay navigation slightly to allow user to read the message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.unexpectedError}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPasswordTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: SvgPicture.asset(
                      'images/neqat_logo/logo-color.svg',
                      height: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title and description
                  Text(
                    l10n.resetPasswordTitle,
                    style: AuthStyles.getHeadingStyle(theme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isResetRequested 
                      ? l10n.verificationCodePrompt 
                      : l10n.emailResetPrompt,
                    style: AuthStyles.getSubheadingStyle(theme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AuthStyles.getCardDecoration(theme),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Only show email field if not in reset mode
                        if (!_isResetRequested) ...[
                          TextFormField(
                            controller: _emailController,
                            decoration: AuthStyles.getInputDecoration(
                              theme: theme,
                              hintText: l10n.emailHint,
                              prefixIcon: Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            onPressed: _requestPasswordReset,
                            text: l10n.sendResetInstructionsButton,
                            isLoading: _isLoading,
                          ),
                        ] else ...[
                          // Show token field if manually entered (not auto-filled via URL)
                          if (widget.resetKey == null && widget.code == null && widget.token == null) ...[
                            TextFormField(
                              controller: _codeController,
                              decoration: AuthStyles.getInputDecoration(
                                theme: theme,
                                hintText: l10n.verificationCodeHint,
                                prefixIcon: Icons.verified_user_outlined,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else ...[
                            // Hidden field when auto-filled via URL
                            Visibility(
                              visible: false,
                              child: TextFormField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  hintText: l10n.verificationCodeHint,
                                ),
                              ),
                            ),
                          ],
                          
                          // Password input with show/hide toggle
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: AuthStyles.getInputDecoration(
                              theme: theme,
                              hintText: l10n.newPasswordHint,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                          ),
                          
                          if (_newPasswordController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              "Password requirements:",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AuthStyles.buildValidationIndicator(
                              isValid: _hasMinLength,
                              message: "At least 8 characters",
                              theme: theme,
                            ),
                            AuthStyles.buildValidationIndicator(
                              isValid: _hasLetters,
                              message: "Contains letters",
                              theme: theme,
                            ),
                            AuthStyles.buildValidationIndicator(
                              isValid: _hasNumbers,
                              message: "Contains numbers",
                              theme: theme,
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Confirm password input with show/hide toggle
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: AuthStyles.getInputDecoration(
                              theme: theme,
                              hintText: l10n.confirmNewPasswordHint,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                          ),
                          
                          if (_confirmPasswordController.text.isNotEmpty)
                            AuthStyles.buildValidationIndicator(
                              isValid: _doPasswordsMatch,
                              message: _doPasswordsMatch 
                                ? 'Passwords match' 
                                : l10n.passwordMismatchError,
                              theme: theme,
                            ),
                          
                          const SizedBox(height: 24),
                          
                          CustomButton(
                            onPressed: _resetPassword,
                            text: l10n.resetPasswordButton,
                            isLoading: _isLoading,
                          ),
                          
                          // Only show resend button if we're in the manual flow, not with Keycloak params
                          if (widget.resetKey == null && widget.code == null) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                // Clear and reset the form to request another code
                                setState(() {
                                  _isResetRequested = false;
                                  _codeController.clear();
                                });
                              },
                              child: Text(
                                l10n.resendCodeButton,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                        
                        // Error message
                        if (_errorMessage != null)
                          AuthStyles.buildErrorContainer(_errorMessage!, theme),
                        
                        // Success message
                        if (_successMessage != null && !_isResetRequested)
                          AuthStyles.buildSuccessContainer(_successMessage!, theme),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Remember password link
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      l10n.rememberPasswordLink,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}