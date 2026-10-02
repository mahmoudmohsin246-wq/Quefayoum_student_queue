import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/queue_provider.dart';
import '../widgets/student_card.dart';

class PapersWaitingScreen extends StatelessWidget {
  const PapersWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, provider, child) {
        final students = provider.papersWaitingQueue;
        return _QueueListScaffold(
          title: 'الانتظار - مراجعة الأوراق',
          subtitle: '${students.length} طالب يحتاج مراجعة الأوراق',
          color: Colors.amber.shade800,
          icon: Icons.pending_actions_rounded,
          students: students,
          actionBuilder: (student) => [
            OutlinedButton.icon(
              onPressed: () async {
                final response = await provider.requeuePendingPapers(student.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response.message),
                    backgroundColor: response.success ? Colors.blue : Colors.red,
                  ),
                );
              },
              icon: const Icon(Icons.move_down_rounded, size: 16),
              label: const Text('غير موجود - آخر الطابور'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final response = await provider.setPaperReady(student.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response.message), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('الأوراق كاملة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QueueListScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Student> students;
  final List<Widget> Function(Student) actionBuilder;

  const _QueueListScaffold({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.students,
    required this.actionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            subtitle: Text(subtitle),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('لا يوجد طلاب في هذه القائمة', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return StudentCard(student: student, actions: actionBuilder(student));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
