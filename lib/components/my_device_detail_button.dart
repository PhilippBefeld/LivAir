import 'package:flutter/material.dart';

class MyDeviceDetailButton extends StatelessWidget {

  final String message;

  const MyDeviceDetailButton({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: 250,
        height: 55.0,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8)
        ),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize:  14,
            ),
          ),
        ),
      ),
    );
  }
}
