import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/input_field.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:frontend/presentation/widgets/social_login_button.dart';
import 'package:frontend/app/main.dart';
import 'package:frontend/l10n/app_localizations.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _termsAccepted = false;
  bool _isLoading = false;

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Za-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _handleRegister() async {
    String name = _nameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context)!;

    // Basic validation
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = l10n.emptyFieldsError;
      });
      return;
    }

    if (!_validateEmail(email)) {
      setState(() {
        _errorMessage = l10n.invalidEmailError;
      });
      return;
    }

    if (!_validatePassword(password)) {
      setState(() {
        _errorMessage = l10n.passwordRequirementError;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = l10n.passwordMismatchError;
      });
      return;
    }

    if (!_termsAccepted) {
      setState(() {
        _errorMessage = l10n.termsNotAcceptedError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);

      final result = await authRepository.register(
        username: name,
        email: email,
        password: password,
      );

      if (!result.containsKey('error')) {
        setState(() {
          _successMessage = l10n.registrationSuccessMessage;
          _isLoading = false;
        });

        await _showSuccessDialog();

        if (mounted) {
          context.replace('/login');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? l10n.registrationFailedError;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = l10n.unexpectedError;
        _isLoading = false;
      });
    }
  }

  Future<void> _showSuccessDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.successTitle),
          content: Text(l10n.accountCreatedMessage),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.okButton),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSocialLogin(String providerType) {
    setState(() {
      _errorMessage = AppLocalizations.of(context)!.socialLoginUnavailableError;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
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
                  if (!keyboardOpen || size.height > 650) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.createAccountTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.headlineMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.signUpSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: keyboardOpen ? 16 : 32),
                  ],
                  CustomInputField(
                    controller: _nameController,
                    hintText: l10n.fullNameHint,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _emailController,
                    hintText: l10n.emailHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _passwordController,
                    hintText: l10n.passwordHint,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _confirmPasswordController,
                    hintText: l10n.confirmPasswordHint,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _handleRegister,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            _termsAccepted = value ?? false;
                          });
                        },
                        activeColor: theme.primaryColor,
                      ),
                      Expanded(
                        child: Text(
                          l10n.termsAndConditionsLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: l10n.registerButton,
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                  ),
                  if (!keyboardOpen) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        l10n.orSignUpWith,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialLoginButton(
                          onPressed: () => _handleSocialLogin('github'),
                          assetName: 'images/github.png',
                          size: 30,
                        ),
                        SizedBox(width: isSmallScreen ? 16 : 24),
                        SocialLoginButton(
                          onPressed: () => _handleSocialLogin('google'),
                          assetName: 'images/google.png',
                          size: 30,
                        ),
                        SizedBox(width: isSmallScreen ? 16 : 24),
                        SocialLoginButton(
                          onPressed: () => _handleSocialLogin('twitter'),
                          assetName: 'images/twitter.png',
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.replace('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                        child: Text(l10n.alreadyHaveAccountLink),
                      ),
                    ),
                  ],
                  SizedBox(height: keyboardOpen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}