import 'dart:math' as math;

import 'package:flutter/material.dart';

class CurrencyCircle extends StatelessWidget {
  final String currency;

  const CurrencyCircle({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _getColorForCurrency(currency);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
      child: Center(
        child: Text(
          currency,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColorForCurrency(String currency) {
    switch (currency) {
      case 'USD':
        return Colors.blue[700]!;
      case 'PKR':
        return Colors.green[700]!;
      case 'EUR':
        return Colors.indigo[700]!;
      case 'GBP':
        return Colors.purple[700]!;
      case 'AFN':
        return Colors.orange[700]!;
      default:
        // Generate a random but consistent color based on currency name
        final random = math.Random(
          currency.codeUnitAt(0) +
              (currency.length > 1 ? currency.codeUnitAt(1) : 0),
        );
        return Color.fromRGBO(
          random.nextInt(100) + 100, // Red (avoid too light colors)
          random.nextInt(100) + 100, // Green
          random.nextInt(100) + 100, // Blue
          1,
        );
    }
  }
}
