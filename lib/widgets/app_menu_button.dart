import 'package:flutter/material.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => const SizedBox(
            height: 150,
            child: Center(
              child: Text('Menu options here'),
            ),
          ),
        );
      },
    );
  }
}
