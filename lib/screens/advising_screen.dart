import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/student.dart';
import '../providers/queue_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/student_card.dart';

class AdvisingScreen extends StatelessWidget {
  const AdvisingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, provider, child) {
        final advisingQueue = provider.advisingQueue;

        final waitingCount = provider.advisingWaitingCount;
        final currentStudent = provider.advisingCurrentStudent;
        final nextStudent = provider.advisingNextStudent;

        return Scaffold(
          body: Column(
            children: [
              // Header Title Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  border: Border(bottom: BorderSide(color: Colors.purple.shade100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          kAdvisingEntityName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'متابعة الطلاب المحولين للإرشاد الأكاديمي من المشرفين',
                          style: TextStyle(fontSize: 11, color: Colors.purple),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Queue Stats Card for Academic Advising
              QueueStatsHeader(
                waitingCount: waitingCount,
                currentStudent: currentStudent,
                nextStudent: nextStudent,
              ),

              // Advising Queue Header & Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      'طابور الإرشاد الأكاديمي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${advisingQueue.length} طالب',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Advising Queue List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchQueue(),
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : advisingQueue.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 64, color: Colors.purple.shade200),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا يوجد طلاب في انتظار الإرشاد الأكاديمي حالياً',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: advisingQueue.length,
                              padding: const EdgeInsets.only(bottom: 24),
                              itemBuilder: (context, index) {
                                final student = advisingQueue[index];
                                return StudentCard(
                                  student: student,
                                  actions: _buildAdvisingActions(context, provider, student),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Action Buttons for Academic Advising Screen
  List<Widget> _buildAdvisingActions(BuildContext context, QueueProvider provider, Student student) {
    final List<Widget> actions = [];

    // If status is WAITING_ADVISING -> Option to Call to Advising
    if (student.status == StudentStatus.waitingAdvising) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            final res = await provider.callToAdvising(student.id);
            if (context.mounted && res.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم استدعاء الطالب ${student.name} إلى جلسة الإرشاد الأكاديمي'),
                  backgroundColor: Colors.purple,
                ),
              );
            }
          },
          icon: const Icon(Icons.campaign_rounded, size: 16),
          label: const Text('استدعاء للإرشاد (Call to Advising)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // If status is IN_ADVISING -> Option to Finish Advising
    if (student.status == StudentStatus.inAdvising) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            final res = await provider.finishAdvising(student.id);
            if (context.mounted && res.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إنهاء جلسة الإرشاد للطالب ${student.name} ونقله للمكتملين'),
                  backgroundColor: Colors.teal,
                ),
              );
            }
          },
          icon: const Icon(Icons.check_circle_rounded, size: 16),
          label: const Text('إنهاء الإرشاد (Finish Advising)'),
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
