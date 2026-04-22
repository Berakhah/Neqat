import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';

class PrivacyPolicyTerms extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const PrivacyPolicyTerms({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            activeColor: activeColor ?? theme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (value) {
              onChanged(value ?? false);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ),
              children: [
                const TextSpan(
                  text: 'I agree to the ',
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _showTermsDialog(context);
                    },
                ),
                const TextSpan(
                  text: ' and ',
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _showPrivacyDialog(context);
                    },
                ),
                const TextSpan(
                  text: ' of Neqat. I understand my data will be processed in accordance with these policies.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildSectionTitle('1. Acceptance of Terms'),
              _buildParagraph(
                'By accessing or using Neqat services, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access our services.'
              ),
              
              _buildSectionTitle('2. User Accounts'),
              _buildParagraph(
                'When you create an account with us, you must provide accurate and complete information. You are responsible for safeguarding the password and for all activities that occur under your account.'
              ),
              
              _buildSectionTitle('3. Content and Conduct'),
              _buildParagraph(
                'Our platform allows you to review and provide feedback on various products. You are responsible for all content you post and your conduct on our platform.'
              ),
              
              _buildSectionTitle('4. Intellectual Property'),
              _buildParagraph(
                'The service and its original content, features, and functionality are owned by Neqat and are protected by international copyright, trademark, and other intellectual property laws.'
              ),
              
              _buildSectionTitle('5. Termination'),
              _buildParagraph(
                'We may terminate or suspend your account and access to our services at our sole discretion, without prior notice or liability, for any reason.'
              ),
              
              _buildSectionTitle('6. Changes to Terms'),
              _buildParagraph(
                'We reserve the right to modify or replace these Terms at any time. It is your responsibility to review these Terms periodically for changes.'
              ),
              
              _buildSectionTitle('7. Governing Law'),
              _buildParagraph(
                'These Terms shall be governed by the laws of the jurisdiction in which Neqat is established, without regard to its conflict of law provisions.'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildSectionTitle('1. Information We Collect'),
              _buildParagraph(
                'We collect personal information that you provide directly to us, such as name, email address, and other profile information. We also collect usage data when you interact with our services.'
              ),
              
              _buildSectionTitle('2. How We Use Your Information'),
              _buildParagraph(
                'We use your information to provide, maintain, and improve our services, communicate with you, and personalize your experience.'
              ),
              
              _buildSectionTitle('3. Information Sharing'),
              _buildParagraph(
                'We may share your information with third-party service providers that perform services on our behalf, but we do not sell your personal information.'
              ),
              
              _buildSectionTitle('4. Data Security'),
              _buildParagraph(
                'We implement appropriate security measures to protect your personal information. However, no method of transmission or storage is 100% secure.'
              ),
              
              _buildSectionTitle('5. Your Rights'),
              _buildParagraph(
                'Depending on your location, you may have certain rights regarding your personal information, including the right to access, correct, or delete your data.'
              ),
              
              _buildSectionTitle('6. Changes to Privacy Policy'),
              _buildParagraph(
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.'
              ),
              
              _buildSectionTitle('7. Contact Us'),
              _buildParagraph(
                'If you have any questions about this Privacy Policy, please contact us at support@neqat.com.'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }
} 