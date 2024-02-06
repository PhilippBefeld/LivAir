import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final void Function(String)? onChanged;
  final String? initialValue;
  final TextInputType? inputType;
  final String? label;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onChanged,
    required this.initialValue,
    this.inputType,
    this.label
  });

  @override
  Widget build(BuildContext context){
    if(initialValue != null)controller.text = initialValue!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!=null ? label! : "",style: const TextStyle(fontSize: 12),),
        const SizedBox(height: 5,),
        TextField(
          onChanged: onChanged,
          keyboardType: inputType ?? TextInputType.text,
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
            ),
            fillColor: Colors.white,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xff90a4ae),fontSize: 14),
          ),

        ),
      ],
    );
  }
}