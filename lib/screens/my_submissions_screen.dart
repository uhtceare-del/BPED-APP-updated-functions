import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/submission_provider.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This uses your existing logic to filter by the logged-in student's UID
    final mySubmissionsAsync = ref.watch(mySubmissionsProvider);

    return Scaffold(
      body: mySubmissionsAsync.when(
        data: (subs) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subs.length,
          itemBuilder: (context, index) {
            final sub = subs[index];
            return Card(
              child: ListTile(
                title: Text("Task ID: ${sub.taskId}"), // Ideally fetch Task Name here
                subtitle: Text("Submitted on: ${sub.submittedAt.day}/${sub.submittedAt.month}"),
                trailing: Text(
                  sub.grade ?? "Waiting for Grade",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sub.grade != null ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}