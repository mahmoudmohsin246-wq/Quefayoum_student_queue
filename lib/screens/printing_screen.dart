import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';
import '../widgets/student_card.dart';

class PrintingScreen extends StatelessWidget {
  const PrintingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, provider, child) {
        final students = provider.printingQueue;
        return Scaffold(
          body: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.print_rounded, color: Colors.white),
                ),
                title: const Text('الطباعة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                subtitle: Text('${students.length} طالب أنهى خدمة الدكتور وينتظر الطباعة'),
              ),
              Expanded(
                child: students.isEmpty
                    ? const Center(child: Text('لا يوجد طلاب في انتظار الطباعة', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return StudentCard(
                            student: student,
                            actions: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final response = await provider.setMaterialsPrinted(student.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response.success
                                            ? 'تمت الطباعة ونقل الطالب إلى الإرشاد الأكاديمي'
                                            : response.message,
                                      ),
                                      backgroundColor: response.success ? Colors.purple : Colors.red,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.print_rounded, size: 16),
                                label: const Text('تمت طباعة الورقة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
