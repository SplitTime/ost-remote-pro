import 'package:flutter/material.dart';

class NumPad extends StatelessWidget {
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;

  const NumPad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['*','0','←'],
    ];

    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Row(
            children: row.map((label) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2), // minimal gaps
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0), // Remove minimum size constraint
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Remove extra tap area
                    ),
                    onPressed: () {
                      if (label == '←') {
                        onBackspace();
                      } else {
                        onNumberPressed(label);
                      }
                    },
                    child: Center(
                      child: label == '←'
                          ? const Icon(Icons.backspace, size: 28)
                          : Text(label, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}