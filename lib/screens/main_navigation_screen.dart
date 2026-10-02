import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';
import '../services/excel_export_service.dart';
import 'advising_screen.dart';
import 'completed_students_screen.dart';
import 'doctors_dashboard_screen.dart';
import 'papers_waiting_screen.dart';
import 'printing_screen.dart';
import 'registration_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Default to Doctors Dashboard View
  bool _isExporting = false;
  int _shownNotificationVersion = 0;

  final List<Widget> _screens = const [
    RegistrationScreen(),
    PapersWaitingScreen(),
    DoctorsDashboardScreen(),
    PrintingScreen(),
    AdvisingScreen(),
    CompletedStudentsScreen(),
  ];

  Future<void> _exportExcel(BuildContext context, QueueProvider provider) async {
    setState(() => _isExporting = true);

    try {
      await ExcelExportService.exportQueueToExcel(
        completedStudents: provider.completedForSelectedDate,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تصدير ملف الإكسل بنجاح!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تصدير ملف الإكسل: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, provider, child) {
        if (provider.notificationVersion > _shownNotificationVersion &&
            provider.latestNotification != null) {
          _shownNotificationVersion = provider.notificationVersion;
          final message = provider.latestNotification!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(message)),
                    ],
                  ),
                  backgroundColor: Colors.deepPurple,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
          });
        }
        final isCompact = MediaQuery.sizeOf(context).width < 600;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/branding/fayoum_logo.jpg',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظام إدارة طابور الطلاب',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Firebase Firestore Real-time System',
                      style: TextStyle(fontSize: 10, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Error indicator badge if any
              if (provider.errorMessage != null)
                IconButton(
                  tooltip: provider.errorMessage,
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),

              // Export Excel Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : () => _exportExcel(context, provider),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.table_chart_rounded, size: 18),
                  label: Text(
                    isCompact
                        ? (_isExporting ? '...' : 'Excel')
                        : (_isExporting ? 'جاري التصدير...' : 'تصدير Excel'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Action loading bar indicator
              if (provider.isActionLoading)
                const LinearProgressIndicator(minHeight: 3, color: Colors.blue),

              // Active Screen View
              Expanded(
                child: _screens[_currentIndex],
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            labelBehavior: isCompact
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.how_to_reg_outlined),
                selectedIcon: Icon(Icons.how_to_reg_rounded),
                label: 'التسجيل',
              ),
              NavigationDestination(
                icon: Icon(Icons.pending_actions_outlined),
                selectedIcon: Icon(Icons.pending_actions_rounded),
                label: 'الانتظار',
              ),
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'لوحة الدكاترة',
              ),
              NavigationDestination(
                icon: Icon(Icons.print_outlined),
                selectedIcon: Icon(Icons.print_rounded),
                label: 'الطباعة',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon: Icon(Icons.psychology_rounded),
                label: 'الإرشاد الأكاديمي',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'السجل',
              ),
            ],
          ),
        );
      },
    );
  }
}
