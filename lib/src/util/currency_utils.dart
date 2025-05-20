import 'package:flutter/material.dart';

String getCurrencySymbol(String code) {
  switch (code) {
    case 'AED':
      return 'AED ';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'INR':
      return '₹';
    case 'AFN':
      return 'Af ';
    case 'PKR':
      return '₨ ';
    case '':
      return '\$ '; // Default symbol for total amounts
    default:
      return '$code ';
  }
}

String getCurrencyName(String code) {
  switch (code) {
    case 'USD':
      return 'US Dollar';
    case 'AED':
      return 'UAE Dirham';
    case 'EUR':
      return 'Euro';
    case 'INR':
      return 'Indian Rupee';
    case 'AFN':
      return 'Afghan Afghani';
    case 'PKR':
      return 'Pakistani Rupee';
    default:
      return code;
  }
}

String getCurrencyFlag(String code) {
  switch (code) {
    case 'USD':
      return '🇺🇸';
    case 'AED':
      return '🇦🇪';
    case 'EUR':
      return '🇪🇺';
    case 'INR':
      return '🇮🇳';
    case 'AFN':
      return '🇦🇫';
    case 'PKR':
      return '🇵🇰';
    default:
      return '🌐';
  }
}

Color getCurrencyColor(String code) {
  switch (code) {
    case 'USD':
      return const Color(0xFF2E8B57); // Green
    case 'AED':
      return const Color(0xFF0A6EBD); // Blue
    case 'EUR':
      return const Color(0xFF4169E1); // Royal Blue
    case 'INR':
      return const Color(0xFFFF8C00); // Orange
    case 'AFN':
      return const Color(0xFF9370DB); // Purple
    case 'PKR':
      return const Color(0xFF228B22); // Forest Green
    default:
      return Colors.grey;
  }
}
