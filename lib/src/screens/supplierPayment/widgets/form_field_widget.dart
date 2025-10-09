import 'package:flutter/material.dart';

/// Reusable dropdown field widget
class CustomDropdownField extends StatelessWidget {
  final String label;
  final dynamic value;
  final List<Map<String, dynamic>> items;
  final Function(dynamic) onChanged;
  final String displayKey;
  final String valueKey;
  final bool isString;
  final bool isRequired;
  final String? errorText;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.displayKey,
    required this.valueKey,
    this.isString = false,
    this.isRequired = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
              width: errorText != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<dynamic>(
            value: value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
            hint: Text(
              'Select $label',
              style: const TextStyle(color: Colors.grey),
            ),
            isExpanded: true,
            items:
                items.map((item) {
                  return DropdownMenuItem<dynamic>(
                    value:
                        isString
                            ? item[valueKey] as String
                            : item[valueKey] as int,
                    child: Text(
                      item[displayKey]?.toString() ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Reusable text field widget
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final bool enabled;
  final bool isRequired;
  final Function(String)? onChanged;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.enabled = true,
    this.isRequired = false,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
              width: errorText != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Reusable date field widget
class CustomDateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const CustomDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF26A69A),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
