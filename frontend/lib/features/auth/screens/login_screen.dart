import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/input_field.dart';
import 'package:frontend/presentation/widgets/button.dart';
import 'package:frontend/presentation/widgets/social_login_button.dart';
import 'package:frontend/app/main.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/l10n/app_localizations.dart';

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

  Future<void> _handleLogin() async {
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
      final authRepository = ref.read(authRepositoryProvider);

      final result = await authRepository.login(
        email: email,
        password: password,
      );

      if (result.containsKey('error') && result['error'] == true) {
        setState(() {
          _errorMessage = result['message'] ?? l10n.loginFailedError;
          _isLoading = false;
        });
        return;
      }

      // Store access token
      if (result.containsKey('access')) {
        final accessToken = result['access'];
        ref.read(authProvider.notifier).setToken(accessToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        print('Stored access token: $accessToken');
      } else {
        print('Warning: No access token in login response');
      }

      // Update user data
      if (result.containsKey('user')) {
        final userData = result['user'];
        ref.read(userProvider.notifier).setUserData(userData);

        final isAdmin =
            userData.containsKey('is_superuser')
                ? userData['is_superuser'] == true
                : false;

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
      _errorMessage = AppLocalizations.of(context)!.socialLoginUnavailableError;
    });
  }

  void _navigateToForgotPassword() {
    context.go('/forgotpassword');
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: SvgPicture.asset(
                    'images/neqat_logo/logo-color.svg',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomInputField(
                  controller: _emailController,
                  hintText: l10n.emailHint,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  controller: _passwordController,
                  hintText: l10n.passwordHint,
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToForgotPassword,
                    child: Text(
                      l10n.forgotPasswordLink,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: _handleLogin,
                  text: l10n.loginButton,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(l10n.orContinueWith),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialLoginButton(
                      assetName: 'images/google.png',
                      onPressed: () => _handleSocialLogin('google'),
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    SocialLoginButton(
                      assetName: 'images/twitter.png',
                      onPressed: () => _handleSocialLogin('twitter'),
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    SocialLoginButton(
                      assetName: 'images/github.png',
                      onPressed: () => _handleSocialLogin('github'),
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.noAccountPrompt),
                    TextButton(
                      onPressed: () {
                        context.go('/signup');
                      },
                      child: Text(
                        l10n.signUpLink,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
    );
  }
}
