import 'package:flutter/material.dart';

class TwoStateToggle extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const TwoStateToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TwoStateToggle> createState() => _TwoStateToggleState();
}

class _TwoStateToggleState extends State<TwoStateToggle> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.label),
        const SizedBox(width: 8),
        Switch(
          value: widget.value,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}