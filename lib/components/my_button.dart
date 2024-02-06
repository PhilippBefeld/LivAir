import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {

  final Function()? onTap;
  final double? width;
  final double? heigth;
  final String textInhalt;
  final EdgeInsetsGeometry? padding;
  final Alignment? alignment;

  const MyButton({
    super.key,
    required this.onTap,
    this.width,
    this.heigth,
    required this.textInhalt,
    this.padding,
    this.alignment
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: alignment ?? Alignment.center,
        child: Container(
          width: width ?? 270,
          height: heigth ?? 70,
          padding: padding ?? const EdgeInsets.all(25),
          margin: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8)
          ),
          child: Center(
            child: Text(
              textInhalt,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize:  16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
