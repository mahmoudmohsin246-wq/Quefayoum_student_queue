import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';
import '../widgets/student_card.dart';

class CompletedStudentsScreen extends StatelessWidget {
  const CompletedStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, provider, child) {
        final students = provider.completedForSelectedDate;

        return Scaffold(
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سجل الطلاب المكتملين',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${students.length} طالب مكتمل',
                          style: const TextStyle(fontSize: 12, color: Colors.teal),
                        ),
                        Text(
                          'اختر يومًا لعرض الطلاب المكتملين وتصديرهم',
                          style: TextStyle(fontSize: 11, color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!provider.isLoading && provider.historyDates.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: provider.historyDates.map((date) {
                      final selected = date == provider.selectedHistoryDate;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(date),
                          selected: selected,
                          onSelected: (_) => provider.setSelectedHistoryDate(date),
                          selectedColor: Colors.teal,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.teal.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : students.isEmpty
                        ? const Center(
                            child: Text(
                              'لا يوجد طلاب مكتملون في هذا اليوم',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              return StudentCard(
                                student: students[index],
                                actions: const [],
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
