import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const sm = [
    BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x11000000)),
  ];

  static const md = [
    BoxShadow(blurRadius: 16, offset: Offset(0, 4), color: Color(0x16000000)),
  ];

  static const lg = [
    BoxShadow(blurRadius: 24, offset: Offset(0, 8), color: Color(0x22000000)),
  ];
}
