import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- Riverpod added
import '../models/question_model.dart';
import '../providers/task_provider.dart';

// Changed to ConsumerStatefulWidget
class CreateQuestionScreen extends ConsumerStatefulWidget {
  final String taskId;

  const CreateQuestionScreen({super.key, required this.taskId});

  @override
  ConsumerState<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _questionController = TextEditingController();

  final List<TextEditingController> _choiceControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  int _correctAnswerIndex = 0;
  bool _isLoading = false; // Added to prevent double-tapping

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addChoice() {
    setState(() {
      _choiceControllers.add(TextEditingController());
    });
  }

  void _removeChoice(int index) {
    setState(() {
      _choiceControllers[index].dispose();
      _choiceControllers.removeAt(index);

      if (_correctAnswerIndex >= _choiceControllers.length) {
        _correctAnswerIndex = 0;
      }
    });
  }

  Future<void> _saveQuestion() async {
    final choicesText = _choiceControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (_questionController.text.trim().isEmpty || choicesText.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question and at least 2 choices.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create the model
    final newQuestion = QuestionModel(
      id: '', // Firestore generates the actual document ID automatically
      taskId: widget.taskId,
      questionText: _questionController.text.trim(),
      choices: choicesText,
      correctAnswerIndex: _correctAnswerIndex,
    );

    try {
      // Call the repository via Riverpod
      await ref.read(taskRepositoryProvider).addQuestion(newQuestion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question successfully saved!')),
        );
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save question: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Quiz Question')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choices (Select the radio button for the correct answer):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _choiceControllers.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() => _correctAnswerIndex = value);
                        }
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _choiceControllers[index],
                        decoration: InputDecoration(hintText: 'Choice ${index + 1}'),
                      ),
                    ),
                    if (_choiceControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeChoice(index),
                      ),
                  ],
                );
              },
            ),

            TextButton.icon(
              onPressed: _addChoice,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Choice'),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveQuestion,
                child: _isLoading
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text('Save Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}