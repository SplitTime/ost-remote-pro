import 'package:flutter/material.dart';

class CustomDropDownMenu extends StatefulWidget {
  final List<String> items;
  final String hint;
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const CustomDropDownMenu({
    super.key,
    required this.items,
    required this.hint,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<CustomDropDownMenu> createState() => _CustomDropDownMenuState();
}

class _CustomDropDownMenuState extends State<CustomDropDownMenu> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: Text(widget.hint),
      value: selectedValue,
      items: widget.items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedValue = newValue;
        });
        widget.onChanged(newValue);
      },
    );
  }
}