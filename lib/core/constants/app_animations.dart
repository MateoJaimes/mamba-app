import 'package:flutter/material.dart';

abstract final class AppAnimations {
  AppAnimations._();

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);

  static const curve = Curves.easeInOut;
}
