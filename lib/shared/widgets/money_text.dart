import 'package:flutter/material.dart';
import '../../core/services/currency_service.dart';

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.maxLines,
    this.overflow,
  });
  final num amount;
  final String prefix, suffix;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CurrencyService.instance,
    builder: (_, _) => Text(
      '$prefix${CurrencyService.instance.format(amount)}$suffix',
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}
