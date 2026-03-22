import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import 'create_question_screen.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedClassId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class section.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final instructorId =
        ref.read(authControllerProvider).currentUser?.uid ?? '';

    final newTask = TaskModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      maxScore: int.tryParse(_scoreController.text) ?? 100,
      deadline: _selectedDate,
      lessonId: null,
      instructorId: instructorId,
      classId: _selectedClassId!,
    );

    try {
      final taskId =
          await ref.read(taskRepositoryProvider).createTask(newTask);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateQuestionScreen(taskId: taskId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(allClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task / Quiz',
            style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Class picker
            classesAsync.when(
              data: (classes) => DropdownButtonFormField<String>(
                initialValue: _selectedClassId,
                hint: const Text('Select Class Section'),
                decoration: const InputDecoration(
                  labelText: 'Class Section',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: classes
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.className} — ${c.subject}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClassId = v),
                validator: (v) =>
                    v == null ? 'Select a class section' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) =>
                  const Text('Could not load classes.'),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g. Midterm Quiz or Basketball Spike Demo',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max Points',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || int.tryParse(v) == null)
                            ? 'Enter a number'
                            : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month, color: lnuNavy),
                    label: Text(
                      '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                      style: const TextStyle(color: lnuNavy),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: lnuNavy),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "After saving you'll be taken to add quiz questions. "
                      'Skip that step to use this as a file-submission task.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: lnuNavy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE & ADD QUESTIONS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
