import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapoLogo extends StatelessWidget {
  const MapoLogo({super.key, this.symbolOnly = false, this.width = 160});

  final bool symbolOnly;
  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    symbolOnly
        ? 'assets/branding/mapo-symbol.svg'
        : 'assets/branding/mapo-logo.svg',
    width: width,
    height: width * (symbolOnly ? 184 / 264 : 188 / 725),
    semanticsLabel: 'MAPO',
  );
}
