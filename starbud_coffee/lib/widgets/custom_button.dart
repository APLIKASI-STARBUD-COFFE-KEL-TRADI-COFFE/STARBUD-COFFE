import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF4E342E),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}