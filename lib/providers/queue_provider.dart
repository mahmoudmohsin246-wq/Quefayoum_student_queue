import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/student.dart';
import '../services/firestore_service.dart';

class QueueProvider extends ChangeNotifier {
  List<Student> _activeQueue = [];
  List<Student> _completedQueue = [];

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  String _selectedDoctor = kDoctorsList.first;
  String _searchQuery = '';
  String? _selectedHistoryDate;
  String? _latestNotification;
  int _notificationVersion = 0;
  bool _activeStreamInitialized = false;

  StreamSubscription<List<Student>>? _activeQueueSubscription;
  StreamSubscription<List<Student>>? _completedQueueSubscription;

  QueueProvider() {
    _initFirestoreStreams();
  }
  List<Student> get papersWaitingQueue => _activeQueue
      .where((s) => s.status == StudentStatus.pendingPapers)
      .toList()
    ..sort((a, b) => a.registrationTime.compareTo(b.registrationTime));

  List<Student> get printingQueue => _activeQueue
      .where((s) => s.status == StudentStatus.waitingAdvising && !s.materialsPrinted)
      .toList()
    ..sort((a, b) => a.completionTime.compareTo(b.completionTime));

  /// Initialize real-time Firestore listeners for active and completed queues
  Future<ApiResponse> finishDoctorService(String studentId) {
    return _executeAction(() => FirestoreService.finishDoctorService(studentId));
  }

  Future<ApiResponse> requeueStudent(String studentId) {
    return _executeAction(() => FirestoreService.requeueStudent(studentId));
  }

  Future<ApiResponse> requeuePendingPapers(String studentId) {
    return _executeAction(() => FirestoreService.requeuePendingPapers(studentId));
  }

  void _initFirestoreStreams() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (Firebase.apps.isEmpty) {
      _isLoading = false;
      _errorMessage = 'لم تتم تهيئة Firebase بعد. أضف firebase_options.dart وأعد تشغيل التطبيق.';
      notifyListeners();
      return;
    }

    _activeQueueSubscription = FirestoreService.getActiveQueueStream().listen(
      (students) {
        _detectQueueNotifications(students);
        _activeQueue = students;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'خطأ في الاتصال بالفايربيس (قائمة النشط): ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );

    _completedQueueSubscription = FirestoreService.getCompletedQueueStream().listen(
      (students) {
        _completedQueue = students;
        final dates = historyDates;
        if (_selectedHistoryDate == null || !dates.contains(_selectedHistoryDate)) {
          _selectedHistoryDate = dates.isEmpty ? null : dates.first;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'خطأ في الاتصال بالفايربيس (قائمة المكتملين): ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _activeQueueSubscription?.cancel();
    _completedQueueSubscription?.cancel();
    super.dispose();
  }

  // Getters
  List<Student> get activeQueue => _activeQueue;
  List<Student> get completedQueue => _completedQueue;
  List<String> get historyDates {
    final dates = _completedQueue
        .map((student) => student.completionTime.trim().split(' ').first)
        .where((date) => date.isNotEmpty && date != ' ')
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  String? get selectedHistoryDate => _selectedHistoryDate;
  String? get latestNotification => _latestNotification;
  int get notificationVersion => _notificationVersion;

  void clearNotification() {
    _latestNotification = null;
    notifyListeners();
  }

  void _detectQueueNotifications(List<Student> students) {
    if (!_activeStreamInitialized) {
      _activeStreamInitialized = true;
      return;
    }

    final previousById = {for (final student in _activeQueue) student.id: student};
    for (final student in students) {
      final previous = previousById[student.id];
      if (previous == null) continue;

      if (previous.status == StudentStatus.waitingAdvising &&
          !previous.materialsPrinted &&
          student.materialsPrinted) {
        _publishNotification(
          'تم تحويل ${student.name} إلى الإرشاد الأكاديمي',
        );
      } else if (!previous.materialsPrinted && student.materialsPrinted) {
        _publishNotification(
          'تم تسجيل طباعة ورقة تسجيل المواد للطالب ${student.name}',
        );
      }
    }
  }

  void _publishNotification(String message) {
    _latestNotification = message;
    _notificationVersion++;
    notifyListeners();
  }

  List<Student> get completedForSelectedDate {
    final date = _selectedHistoryDate;
    if (date == null) return const [];
    return _completedQueue
        .where((student) => student.completionTime.startsWith(date))
        .toList();
  }
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String get selectedDoctor => _selectedDoctor;
  String get searchQuery => _searchQuery;

  // Setters
  void setSelectedDoctor(String doctor) {
    _selectedDoctor = doctor;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedHistoryDate(String date) {
    if (_selectedHistoryDate == date) return;
    _selectedHistoryDate = date;
    notifyListeners();
  }

  /// Kept for pull-to-refresh controls; Firestore streams update automatically.
  Future<void> fetchQueue() async {}

  // ==================== COMPUTED QUEUES & STATS ====================

  /// Filter active queue by doctor and status PENDING_PAPERS using string normalization
  List<Student> pendingPapersForDoctor(String doctor) {
    return _activeQueue.where((s) {
      final matchesDoctor = isDoctorMatch(s.doctor, doctor);
      final isPending = s.status == StudentStatus.pendingPapers;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.id.toLowerCase().contains(query);
      return matchesDoctor && isPending && matchesSearch;
    }).toList();
  }

  /// Filter the doctor's queue; advising students belong only to the advising screen.
  List<Student> activeQueueForDoctor(String doctor) {
    return _activeQueue.where((s) {
      final matchesDoctor = isDoctorMatch(s.doctor, doctor);
      final isActive = s.status == StudentStatus.waiting ||
          s.status == StudentStatus.inProgress;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.id.toLowerCase().contains(query);
      return matchesDoctor && isActive && matchesSearch;
    }).toList();
  }

  /// All active students assigned to Doctor (PENDING_PAPERS, WAITING, IN_PROGRESS, WAITING_ADVISING, IN_ADVISING)
  List<Student> allActiveStudentsForDoctor(String doctor) {
    return _activeQueue.where((s) {
      final matchesDoctor = isDoctorMatch(s.doctor, doctor);
      final isActive = s.status != StudentStatus.done && s.status != StudentStatus.cancelled;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.id.toLowerCase().contains(query);
      return matchesDoctor && isActive && matchesSearch;
    }).toList();
  }

  /// Filter active queue for Academic Advising (WAITING_ADVISING & IN_ADVISING)
  List<Student> get advisingQueue {
    final students = _activeQueue.where((s) {
      final isAdvising = (s.status == StudentStatus.waitingAdvising || s.status == StudentStatus.inAdvising) &&
          s.materialsPrinted;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.id.toLowerCase().contains(query) ||
          s.doctor.toLowerCase().contains(query);
      return isAdvising && matchesSearch;
    }).toList();

    // FIFO for advising: the student who finished with the doctor first
    // should appear first, regardless of original registration order.
    students.sort((a, b) {
      final aTime = a.advisingTime.isNotEmpty ? a.advisingTime : a.completionTime;
      final bTime = b.advisingTime.isNotEmpty ? b.advisingTime : b.completionTime;
      return aTime.compareTo(bTime);
    });
    return students;
  }

  /// Doctor Queue Stats using normalized string matching
  int waitingCountForDoctor(String doctor) {
    return _activeQueue.where((s) => isDoctorMatch(s.doctor, doctor) && s.status == StudentStatus.waiting).length;
  }

  Student? currentStudentForDoctor(String doctor) {
    try {
      return _activeQueue.firstWhere((s) => isDoctorMatch(s.doctor, doctor) && s.status == StudentStatus.inProgress);
    } catch (_) {
      return null;
    }
  }

  Student? nextStudentForDoctor(String doctor) {
    try {
      return _activeQueue.firstWhere((s) => isDoctorMatch(s.doctor, doctor) && s.status == StudentStatus.waiting);
    } catch (_) {
      return null;
    }
  }

  /// Academic Advising Stats
  int get advisingWaitingCount {
    return _activeQueue.where((s) =>
        s.status == StudentStatus.waitingAdvising && s.materialsPrinted).length;
  }

  Student? get advisingCurrentStudent {
    try {
      return _activeQueue.firstWhere((s) => s.status == StudentStatus.inAdvising && s.materialsPrinted);
    } catch (_) {
      return null;
    }
  }

  Student? get advisingNextStudent {
    try {
      return _activeQueue.firstWhere((s) => s.status == StudentStatus.waitingAdvising && s.materialsPrinted);
    } catch (_) {
      return null;
    }
  }

  // ==================== ACTIONS & FIRESTORE CALLS ====================

  /// Internal helper to execute Firestore actions
  Future<ApiResponse> _executeAction(Future<ApiResponse> Function() actionCall) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final result = await actionCall();
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'خطأ أثناء تنفيذ العملية: ${e.toString()}',
      );
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  /// Screen 1: Add new student
  Future<ApiResponse> addStudent({
    required String name,
    required String nationalId,
    required String doctor,
    required PaperStatus paperStatus,
  }) {
    return _executeAction(() => FirestoreService.addStudent(
          name: name,
          nationalId: nationalId,
          doctor: doctor,
          paperStatus: paperStatus,
        ));
  }

  /// Screen 2: Promote Pending Papers to WAITING
  Future<ApiResponse> setPaperReady(String studentId) {
    return _executeAction(() => FirestoreService.setPaperReady(studentId));
  }

  Future<ApiResponse> setMaterialsPrinted(String studentId) {
    return _executeAction(() => FirestoreService.setMaterialsPrinted(studentId));
  }

  Future<ApiResponse> deleteStudent(String studentId) {
    return _executeAction(() => FirestoreService.deleteStudent(studentId));
  }

  /// Screen 2: Call student to start service (WAITING -> IN_PROGRESS)
  Future<ApiResponse> callStudent(String studentId) {
    return _executeAction(() => FirestoreService.updateStatus(
          studentId: studentId,
          newStatus: StudentStatus.inProgress,
        ));
  }

  /// Screen 2: Transfer student from doctor to Academic Advising (IN_PROGRESS -> WAITING_ADVISING)
  Future<ApiResponse> sendToAdvising(String studentId) {
    return _executeAction(() => FirestoreService.sendToAdvising(studentId));
  }

  /// Screen 2: Complete doctor service (IN_PROGRESS -> DONE, moves to Completed tab)
  Future<ApiResponse> completeService(String studentId) {
    return _executeAction(() => FirestoreService.completeService(
          studentId,
          finalStatus: StudentStatus.done,
        ));
  }

  /// Screen 3: Call student for Academic Advising (WAITING_ADVISING -> IN_ADVISING)
  Future<ApiResponse> callToAdvising(String studentId) {
    return _executeAction(() => FirestoreService.updateStatus(
          studentId: studentId,
          newStatus: StudentStatus.inAdvising,
        ));
  }

  /// Screen 3: Finish Academic Advising (IN_ADVISING -> DONE, moves to Completed tab)
  Future<ApiResponse> finishAdvising(String studentId) {
    return _executeAction(() => FirestoreService.completeService(
          studentId,
          finalStatus: StudentStatus.done,
        ));
  }
}
