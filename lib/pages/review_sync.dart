import 'package:flutter/material.dart';

class ReviewSyncPage extends StatefulWidget {
  const ReviewSyncPage({super.key});

  @override
  State<ReviewSyncPage> createState() => _ReviewSyncPageState();
}

class _ReviewSyncPageState extends State<ReviewSyncPage> {
  String? sortBy = "Name"; // Default sort by Name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review/Sync'),
      ),
      body: const Center(
        child: Text('Review Sync Page Content Here'),
      ),
    );
  }
}