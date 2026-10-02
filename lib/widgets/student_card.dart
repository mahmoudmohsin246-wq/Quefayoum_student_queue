import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/student.dart';
import 'status_badge.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final List<Widget>? actions;

  const StudentCard({super.key, required this.student, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Student Name & Status Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: student.status.color.withOpacity(0.15),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : 'ط',
                    style: TextStyle(
                      color: student.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (student.materialsPrinted) ...[
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(
                              Icons.print_rounded,
                              size: 14,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'تمت طباعة ورقة تسجيل المواد',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (student.nationalId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SelectableText(
                                'الرقم القومي: ${student.nationalId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'نسخ الرقم القومي',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Colors.blueGrey.shade500,
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: student.nationalId),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ الرقم القومي'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.doctor,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.id,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: student.status, compact: true),
              ],
            ),

            const SizedBox(height: 12),

            // Metadata row (Paper Status & Registration Time)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        student.paperStatus == PaperStatus.ready
                            ? Icons.assignment_turned_in_rounded
                            : Icons.assignment_late_rounded,
                        size: 15,
                        color: student.paperStatus == PaperStatus.ready
                            ? Colors.green
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الأوراق: ${student.paperStatus.arabicLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: student.paperStatus == PaperStatus.ready
                              ? Colors.green.shade800
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  if (student.registrationTime.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          student.registrationTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Optional Actions Section
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
