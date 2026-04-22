import 'package:flutter/material.dart';

class TermsCheckbox extends StatefulWidget {
  final ValueChanged<bool>? onChanged;

  const TermsCheckbox({super.key, this.onChanged});

  @override
  _TermsCheckboxState createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: const Text('I agree to the Terms and Conditions'),
      value: _isChecked,
      onChanged: (value) {
        setState(() {
          _isChecked = value ?? false;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(value ?? false);
        }
      },
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.blue,
      checkColor: Colors.white,
    );
  }
}