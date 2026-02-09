import 'package:flutter/material.dart';

class CustomDropDownMenu extends StatelessWidget {
  final List<String> items;
  final String hint;
  final String? value;
  final ValueChanged<String?> onChanged;

  const CustomDropDownMenu({
    super.key,
    required this.items,
    required this.hint,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: Text(hint),
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged
    );
  }
  
}


