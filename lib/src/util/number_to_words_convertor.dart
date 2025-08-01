String convertAmountToWords(double amount) {
  if (amount == 0) return 'Zero';

  List<String> ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  List<String> tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String convertHundreds(int num) {
    String result = '';

    if (num >= 100) {
      result += ones[num ~/ 100] + ' Hundred ';
      num %= 100;
    }

    if (num >= 20) {
      result += tens[num ~/ 10] + ' ';
      num %= 10;
    }

    if (num > 0) {
      result += ones[num] + ' ';
    }

    return result;
  }

  int integerPart = amount.floor();
  int decimalPart = ((amount - integerPart) * 100).round();

  String result = '';

  if (integerPart >= 10000000) {
    result += convertHundreds(integerPart ~/ 10000000) + 'Crore ';
    integerPart %= 10000000;
  }

  if (integerPart >= 100000) {
    result += convertHundreds(integerPart ~/ 100000) + 'Lakh ';
    integerPart %= 100000;
  }

  if (integerPart >= 1000) {
    result += convertHundreds(integerPart ~/ 1000) + 'Thousand ';
    integerPart %= 1000;
  }

  if (integerPart > 0) {
    result += convertHundreds(integerPart);
  }

  result = result.trim();
  if (result.isEmpty) result = 'Zero';

  if (decimalPart > 0) {
    result += ' and ${convertHundreds(decimalPart).trim()} Paisa';
  }

  return result + ' Only';
}
