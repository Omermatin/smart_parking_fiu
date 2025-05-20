import 'package:flutter/material.dart';
import '../pages/homepage.dart'; // For AppColors

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const MyButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,

      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.backgroundwidget,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
