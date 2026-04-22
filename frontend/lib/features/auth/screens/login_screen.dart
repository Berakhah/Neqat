import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:frontend/presentation/widgets/social_login_button.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/features/auth/presentation/style/auth_styles.dart';
import 'package:frontend/features/auth/data/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Check for biometric login possibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricOption();
      
      // Check for web social login callbacks
      ref.read(authProvider.notifier).checkWebSocialLoginCallback();
    });
  }

  Future<void> _checkBiometricOption() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);
      
      // Check if biometrics are available
      final isAvailable = await biometricService.isBiometricAvailable();
      if (!isAvailable) return;
      
      // Check if biometrics are enabled for a user
      final isEnabled = await biometricService.isBiometricEnabled();
      if (!isEnabled) return;
      
      // Get last logged in email
      final lastEmail = await const FlutterSecureStorage().read(key: 'last_email');
      if (lastEmail == null) return;
      
      // Check if the current account is registered
      final isCurrentAccount = await biometricService.isCurrentAccountRegistered(lastEmail);
      if (!isCurrentAccount) return;
      
      // Show biometric login prompt
      final shouldShow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Biometric Login'),
          content: Text('Do you want to log in as $lastEmail with biometric authentication?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ?? false;
      
      if (shouldShow && mounted) {
        // Store the email for login
        _emailController.text = lastEmail;
        
        // Try biometric authentication
        _handleBiometricLogin();
      }
    } catch (e) {
      // Silently fail - biometric is an optional feature
      debugPrint('Biometric check failed: $e');
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final biometricService = ref.read(biometricServiceProvider);
      
      // Authenticate with biometrics
      final authenticated = await biometricService.authenticate(
        localizedReason: 'Please authenticate to log in',
      );
      
      if (!authenticated) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get stored email
      final email = _emailController.text;
      if (email.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email address';
        });
        return;
      }
      
      // Get stored password - use a secure fetch here
      final secureStorage = const FlutterSecureStorage();
      final password = await secureStorage.read(key: 'auth_password_${email.toLowerCase()}');
      
      if (password == null || password.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No saved password found for biometric authentication';
        });
        return;
      }
      
      // Log in with stored credentials
      await ref.read(authProvider.notifier).login(email, password);
      
      // Check login result
      final authState = ref.read(authProvider);
      
      if (authState.errorMessage != null) {
        setState(() {
          _errorMessage = authState.errorMessage;
          _isLoading = false;
        });
        return;
      }
      
      // Update user data
      if (authState.user != null) {
        ref.read(userProvider.notifier).setUserData(authState.user!);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Save the email for next time
      await secureStorage.write(key: 'last_email', value: email);
      
      // Navigate based on user role
      if (mounted) {
        final isAdmin = authState.user?['is_admin'] == true || 
                      (authState.user?['realm_access'] != null && 
                      authState.user?['realm_access']['roles'] != null && 
                      (authState.user?['realm_access']['roles'] as List).contains('admin'));
        
        if (isAdmin) {
          context.go('/admin');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      setState(() {
        final l10n = AppLocalizations.of(context)!;
        _errorMessage = '${l10n.loginErrorPrefix} $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;
    
    final email = _emailController.text;
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
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
      await ref.read(authProvider.notifier).login(email, password);
      final authState = ref.read(authProvider);

      if (authState.errorMessage != null) {
        setState(() {
          _errorMessage = authState.errorMessage;
          _isLoading = false;
        });
        return;
      }

      // Save credentials for biometric auth if enabled
      final biometricService = ref.read(biometricServiceProvider);
      final isBiometricEnabled = await biometricService.isBiometricEnabled();
      
      if (isBiometricEnabled) {
        // Save password securely for biometric login
        await const FlutterSecureStorage().write(
          key: 'auth_password_${email.toLowerCase()}',
          value: password,
        );
        
        // Save last email
        await const FlutterSecureStorage().write(
          key: 'last_email',
          value: email,
        );
      }

      // Update user data
      if (authState.user != null) {
        ref.read(userProvider.notifier).setUserData(authState.user!);
        final isAdmin = authState.user!.containsKey('is_superuser') ? authState.user!['is_superuser'] == true : false;

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (isAdmin) {
            context.go('/admin');
          } else {
            context.go('/');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.loginErrorPrefix} $e';
        _isLoading = false;
      });
    }
  }

  void _handleSocialLogin(String providerType) {
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
        
        // Update user data if available
        if (authState.user != null) {
          ref.read(userProvider.notifier).setUserData(authState.user!);
          final isAdmin = authState.user!.containsKey('is_superuser') ? 
            authState.user!['is_superuser'] == true : false;
          
          setState(() {
            _isLoading = false;
          });
          
          if (mounted) {
            if (isAdmin) {
              context.go('/admin');
            } else {
              context.go('/');
            }
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            context.go('/');
          }
        }
      }).catchError((e) {
        setState(() {
          final l10n = AppLocalizations.of(context)!;
          _errorMessage = '${l10n.loginErrorPrefix} $e';
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        final l10n = AppLocalizations.of(context)!;
        _errorMessage = '${l10n.loginErrorPrefix} $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToForgotPassword() {
    context.go('/forgot-password');
  }

  void _navigateToSignup() {
    context.go('/signup');
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.emailEmptyError;
    }
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      return l10n.invalidEmailError;
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and branding
                    Center(
                      child: SvgPicture.asset(
                        'images/neqat_logo/logo-color.svg',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Heading
                    Text(
                      l10n.loginTitle,
                      style: AuthStyles.getHeadingStyle(theme),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Login form card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AuthStyles.getCardDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.next,
                            decoration: AuthStyles.getInputDecoration(
                              theme: theme,
                              hintText: l10n.emailHint,
                              prefixIcon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Password field with show/hide toggle
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
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
                          
                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _navigateToForgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.forgotPasswordLink,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          // Error message
                          if (_errorMessage != null)
                            AuthStyles.buildErrorContainer(_errorMessage!, theme),
                          
                          const SizedBox(height: 16),
                          
                          // Login button
                          CustomButton(
                            onPressed: _handleLogin,
                            text: l10n.loginButton,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Or continue with separator
                    AuthStyles.buildOrDivider(l10n.orContinueWith, theme),
                    
                    const SizedBox(height: 24),
                    
                    // Social login buttons
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
                    
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.noAccountPrompt,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToSignup,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                          child: Text(
                            l10n.signUpLink,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
