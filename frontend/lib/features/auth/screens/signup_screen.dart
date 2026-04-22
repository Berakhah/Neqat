import 'package:flutter/material.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:frontend/presentation/widgets/social_login_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/features/auth/presentation/style/auth_styles.dart';
import 'package:frontend/features/auth/presentation/widgets/privacy_policy_terms.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String? _errorMessage;
  String? _successMessage;
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordValid = false;
  bool _hasMinLength = false;
  bool _hasLetters = false;
  bool _hasNumbers = false;
  bool _doPasswordsMatch = false;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Add listeners for password validation
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }
  
  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasLetters = RegExp(r'[A-Za-z]').hasMatch(password);
      _hasNumbers = RegExp(r'[0-9]').hasMatch(password);
      _isPasswordValid = _hasMinLength && _hasLetters && _hasNumbers;
    });
  }
  
  void _validatePasswordMatch() {
    setState(() {
      _doPasswordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  String? _validateEmailField(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.emailEmptyError;
    }
    if (!_validateEmail(value)) {
      return l10n.invalidEmailError;
    }
    return null;
  }

  String? _validateRequiredField(String? value, String fieldName) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return '$fieldName ${l10n.emptyFieldsError.toLowerCase()}';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() != true) return;
    
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context)!;

    // Basic validation
    if (firstName.isEmpty ||
        lastName.isEmpty ||
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

    if (!_isPasswordValid) {
      setState(() {
        _errorMessage = l10n.passwordRequirementError;
      });
      return;
    }

    if (!_doPasswordsMatch) {
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
      await ref.read(authProvider.notifier).register(firstName, lastName, email, password);
      final authState = ref.read(authProvider);

      if (authState.errorMessage != null) {
        setState(() {
          _errorMessage = authState.errorMessage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _successMessage = l10n.registrationSuccessMessage;
          _isLoading = false;
        });

        await _showSuccessDialog();

        if (mounted) {
          context.replace('/login');
        }
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
    final theme = Theme.of(context);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            l10n.successTitle,
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.accountCreatedMessage,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                l10n.okButton,
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      ref.read(authProvider.notifier).socialLogin(providerType).then((_) {
        final authState = ref.read(authProvider);
        
        if (authState.errorMessage != null) {
          setState(() {
            _errorMessage = authState.errorMessage;
            _isLoading = false;
          });
          return;
        }
        
        // Show success dialog and redirect
        setState(() {
          _successMessage = l10n.registrationSuccessMessage;
          _isLoading = false;
        });
        
        _showSuccessDialog().then((_) {
          if (mounted) {
            context.replace('/login');
          }
        });
      }).catchError((e) {
        setState(() {
          _errorMessage = l10n.unexpectedError;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = l10n.unexpectedError;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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
      appBar: AppBar(
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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!keyboardOpen || size.height > 650) ...[
                        // Logo
                        Center(
                          child: SvgPicture.asset(
                            'images/neqat_logo/logo-color.svg',
                            height: 60,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Heading
                        Text(
                          l10n.createAccountTitle,
                          style: AuthStyles.getHeadingStyle(theme),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signUpSubtitle,
                          style: AuthStyles.getSubheadingStyle(theme),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: keyboardOpen ? 16 : 32),
                      ],
                      
                      // Form Fields Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AuthStyles.getCardDecoration(theme),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // First Name field
                            TextFormField(
                              controller: _firstNameController,
                              validator: (value) => _validateRequiredField(value, l10n.firstNameHint),
                              textInputAction: TextInputAction.next,
                              decoration: AuthStyles.getInputDecoration(
                                theme: theme,
                                hintText: l10n.firstNameHint,
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Last Name field
                            TextFormField(
                              controller: _lastNameController,
                              validator: (value) => _validateRequiredField(value, l10n.lastNameHint),
                              textInputAction: TextInputAction.next,
                              decoration: AuthStyles.getInputDecoration(
                                theme: theme,
                                hintText: l10n.lastNameHint,
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              validator: _validateEmailField,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: AuthStyles.getInputDecoration(
                                theme: theme,
                                hintText: l10n.emailHint,
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password field with show/hide toggle
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: AuthStyles.getInputDecoration(
                                theme: theme,
                                hintText: l10n.passwordHint,
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
                            ),
                            
                            // Password requirements indicators
                            if (_passwordController.text.isNotEmpty) ...[
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
                            
                            const SizedBox(height: 16),
                            
                            // Confirm Password field with show/hide toggle
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              decoration: AuthStyles.getInputDecoration(
                                theme: theme,
                                hintText: l10n.confirmPasswordHint,
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
                            ),
                            
                            // Password match indicator
                            if (_confirmPasswordController.text.isNotEmpty)
                              AuthStyles.buildValidationIndicator(
                                isValid: _doPasswordsMatch,
                                message: _doPasswordsMatch 
                                  ? 'Passwords match' 
                                  : l10n.passwordMismatchError,
                                theme: theme,
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Terms and conditions checkbox
                            PrivacyPolicyTerms(
                              value: _termsAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _termsAccepted = value;
                                });
                              },
                              activeColor: theme.primaryColor,
                            ),
                            
                            // Error message
                            if (_errorMessage != null)
                              AuthStyles.buildErrorContainer(_errorMessage!, theme),
                            
                            // Success message
                            if (_successMessage != null)
                              AuthStyles.buildSuccessContainer(_successMessage!, theme),
                            
                            const SizedBox(height: 24),
                            
                            // Register button
                            CustomButton(
                              onPressed: _handleRegister,
                              text: l10n.registerButton,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Or sign up with separator
                      AuthStyles.buildOrDivider(l10n.orSignUpWith, theme),
                      
                      const SizedBox(height: 24),
                      
                      // Social signup buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SocialLoginButton(
                            assetName: 'images/google.png',
                            onPressed: () => _handleSocialLogin('google'),
                            size: 40,
                          ),
                          const SizedBox(width: 24),
                          SocialLoginButton(
                            assetName: 'images/twitter.png',
                            onPressed: () => _handleSocialLogin('twitter'),
                            size: 40,
                          ),
                          const SizedBox(width: 24),
                          SocialLoginButton(
                            assetName: 'images/github.png',
                            onPressed: () => _handleSocialLogin('github'),
                            size: 40,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Already have account link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${l10n.alreadyHaveAccountLink.split('?')[0]}?',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                              child: Text(
                                l10n.loginButton,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}