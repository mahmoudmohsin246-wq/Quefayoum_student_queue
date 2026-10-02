import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/student.dart';
import '../providers/queue_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/student_card.dart';

class DoctorsDashboardScreen extends StatelessWidget {
  const DoctorsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, provider, child) {
        final doctorsList = kDoctorsList;
        final selectedDoctor = provider.selectedDoctor;

        final activeQueue = provider.activeQueueForDoctor(selectedDoctor);

        final waitingCount = provider.waitingCountForDoctor(selectedDoctor);
        final currentStudent = provider.currentStudentForDoctor(selectedDoctor);
        final nextStudent = provider.nextStudentForDoctor(selectedDoctor);

        return Scaffold(
          body: Column(
            children: [
              // 1. Doctor Selector Tabs / Filter Chip Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: doctorsList.map((doc) {
                      final isSelected = doc == selectedDoctor;
                      final count = provider.activeQueueForDoctor(doc).length +
                          provider.pendingPapersForDoctor(doc).length;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          avatar: isSelected
                              ? const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)
                              : CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
                                  ),
                                ),
                          label: Text(doc),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) {
                            provider.setSelectedDoctor(doc);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Divider(height: 1),

              // 2. Queue Stats Header Card
              QueueStatsHeader(
                waitingCount: waitingCount,
                currentStudent: currentStudent,
                nextStudent: nextStudent,
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث عن طالب في طابور د. $selectedDoctor...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) => provider.setSearchQuery(val),
                ),
              ),

              // 3. Scrollable List with Active Queue
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchQueue(),
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            // Active Queue (في الانتظار & جاري الخدمة)
                            _buildSectionHeader(
                              context: context,
                              title: 'الطابور النشط (Active Queue)',
                              count: activeQueue.length,
                              color: Theme.of(context).primaryColor,
                              icon: Icons.queue_play_next_rounded,
                            ),

                            if (activeQueue.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا يوجد طلاب حالياً في طابور $selectedDoctor',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...activeQueue.map((student) => StudentCard(
                                    student: student,
                                    actions: _buildDoctorActions(context, provider, student),
                                  )),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Context-sensitive Action Buttons for Doctor View
  List<Widget> _buildDoctorActions(BuildContext context, QueueProvider provider, Student student) {
    final List<Widget> actions = [];

    actions.add(
      OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('حذف الطالب؟'),
              content: Text(
                'سيتم حذف ${student.name} نهائيًا من الطابور. '
                'استخدم هذا الخيار إذا غادر الطالب أو تم تسجيله بالخطأ.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;

          final response = await provider.deleteStudent(student.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.success ? Colors.red : Colors.orange,
            ),
          );
        },
        icon: const Icon(Icons.delete_outline_rounded, size: 16),
        label: const Text('حذف'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );

    // If status is WAITING -> Option to Call / Start Service
    if (student.status == StudentStatus.waiting) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            final res = await provider.callStudent(student.id);
            if (context.mounted && res.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم استدعاء الطالب ${student.name} لبدء الخدمة'),
                  backgroundColor: Colors.green,
                ),
              );
              actions.add(
                OutlinedButton.icon(
                  onPressed: () async {
                    final response = await provider.requeueStudent(student.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.message), backgroundColor: Colors.orange),
                    );
                  },
                  icon: const Icon(Icons.person_off_outlined, size: 16),
                  label: const Text('غير موجود - آخر الطابور'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade800),
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.record_voice_over, size: 16),
          label: const Text('استدعاء / بدء الخدمة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // If status is IN_PROGRESS -> finish doctor service and move to printing
    if (student.status == StudentStatus.inProgress) {
      actions.add(
        ElevatedButton.icon(
          onPressed: student.materialsPrinted
              ? null
              : () async {
                  final res = await provider.finishDoctorService(student.id);
                  if (context.mounted && res.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نقل الطالب إلى تبويب الطباعة'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: const Text('إنهاء خدمة الدكتور'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return actions;
  }
}
