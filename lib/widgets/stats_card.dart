import 'package:flutter/material.dart';
import '../models/student.dart';

class QueueStatsHeader extends StatelessWidget {
  final int waitingCount;
  final Student? currentStudent;
  final Student? nextStudent;

  const QueueStatsHeader({
    super.key,
    required this.waitingCount,
    this.currentStudent,
    this.nextStudent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'المنتظرين',
                  value: '$waitingCount طالب',
                  subtitle: 'في قائمة الانتظار',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white12),
              Expanded(
                child: _buildStatTile(
                  icon: Icons.record_voice_over_rounded,
                  iconColor: const Color(0xFF4ADE80),
                  title: 'الطالب الحالي',
                  value: currentStudent != null ? currentStudent!.name : 'لا يوجد',
                  subtitle: currentStudent != null ? currentStudent!.id : 'جاهز للاستدعاء',
                ),
              ),
            ],
          ),
          if (nextStudent != null) ...[
            const Divider(color: Colors.white12, height: 24),
            Row(
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                Text(
                  'التالي في الطابور: ',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                Text(
                  nextStudent!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  nextStudent!.id,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
