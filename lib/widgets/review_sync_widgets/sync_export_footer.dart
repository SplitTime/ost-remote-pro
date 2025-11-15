import 'package:flutter/material.dart';

class SyncExportFooter extends StatelessWidget {
  final VoidCallback onSyncPressed;
  final VoidCallback onExportPressed;

  const SyncExportFooter({
    super.key,
    required this.onSyncPressed,
    required this.onExportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 45,
        child: Row(
          children: [
            Expanded(
                flex: 10,
                child: GestureDetector(
                    onTap: onSyncPressed,
                    child: Container(
                      color: Colors.green[700],
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sync',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const Icon(
                            Icons.sync,
                            color: Colors.white,
                          )
                        ],
                      )),
                    ))),
            Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onExportPressed,
                  child: Container(
                    color: Colors.blue[300],
                    child: const Center(
                      child: Icon(
                        Icons.ios_share,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ))
          ],
        ));
  }
}
