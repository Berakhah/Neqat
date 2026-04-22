import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  final int currentPageIndex;

  const OnboardingIndicator({
    super.key,
    required this.currentPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) {
          return Container(
            margin: EdgeInsets.only(left: 5.0),
            width: currentPageIndex == index ? 35 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  currentPageIndex == index ? Color(0xff2B71E0) : Colors.grey,
              borderRadius: BorderRadius.circular(10.0),
            ),
          );
        },
      ),
    );
  }
}
