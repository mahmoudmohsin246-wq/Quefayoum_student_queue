import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/student.dart';

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _studentsRef = _firestore.collection('students');

  /// Helper to get formatted timestamp string: YYYY-MM-DD HH:mm:ss
  static String _getCurrentTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  /// Real-time stream for ACTIVE students queue
  /// Every status except DONE and CANCELLED belongs to the active queue.
  static Stream<List<Student>> getActiveQueueStream() {
    return _studentsRef
        .where('status', whereNotIn: ['DONE', 'CANCELLED'])
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            // Inject document ID if missing in data payload
            if (!data.containsKey('id') || data['id'] == null || data['id'].toString().isEmpty) {
              data['id'] = doc.id;
            }
            return Student.fromJson(data);
          }).toList();

          // Sort by registrationTime ascending (FIFO queue order)
          students.sort((a, b) => a.registrationTime.compareTo(b.registrationTime));
          return students;
        });
  }

  /// Real-time stream for COMPLETED students queue
  /// Completed statuses: DONE, CANCELLED
  static Stream<List<Student>> getCompletedQueueStream() {
    return _studentsRef
        .where('status', whereIn: ['DONE', 'CANCELLED'])
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            if (!data.containsKey('id') || data['id'] == null || data['id'].toString().isEmpty) {
              data['id'] = doc.id;
            }
            return Student.fromJson(data);
          }).toList();

          // Sort completed students by completionTime descending
          students.sort((a, b) => b.completionTime.compareTo(a.completionTime));
          return students;
        });
  }

  /// Action: Add New Student to Firestore
  static Future<ApiResponse> addStudent({
    required String name,
    required String nationalId,
    required String doctor,
    required PaperStatus paperStatus,
  }) async {
    try {
      final normalizedNationalId = nationalId.trim();
      final duplicate = await _studentsRef
          .where('nationalId', isEqualTo: normalizedNationalId)
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        return const ApiResponse(
          success: false,
          message: 'هذا الرقم القومي مسجل بالفعل ولا يمكن تسجيله مرة أخرى',
        );
      }

      final nowStr = _getCurrentTimestamp();
      final customId = 'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${(1000 + (DateTime.now().microsecond % 9000))}';

      final initialStatus = paperStatus == PaperStatus.ready
          ? StudentStatus.waiting.toCode()
          : StudentStatus.pendingPapers.toCode();

      final studentMap = {
        'id': customId,
        'name': name.trim(),
        'nationalId': normalizedNationalId,
        'materialsPrinted': false,
        'doctor': doctor.trim(),
        'status': initialStatus,
        'paperStatus': paperStatus.toCode(),
        'registrationTime': nowStr,
        'calledTime': '',
        'completionTime': '',
      };

      // Set document with customId as document reference key
      await _studentsRef.doc(customId).set(studentMap);

      return ApiResponse(
        success: true,
        message: 'تم إضافة الطالب بنجاح إلى الفايربيس',
        data: Student.fromJson(studentMap),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر إضافة الطالب إلى الفايربيس: ${e.toString()}',
      );
    }
  }

  /// Internal helper to locate student document reference by student ID
  static Future<DocumentReference?> _findStudentDocRef(String studentId) async {
    final directRef = _studentsRef.doc(studentId);
    final directSnap = await directRef.get();
    if (directSnap.exists) {
      return directRef;
    }

    final querySnap = await _studentsRef.where('id', isEqualTo: studentId).limit(1).get();
    if (querySnap.docs.isNotEmpty) {
      return querySnap.docs.first.reference;
    }

    return null;
  }

  /// Delete an active student who left or was registered by mistake.
  static Future<ApiResponse> deleteStudent(String studentId) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return const ApiResponse(
          success: false,
          message: 'لم يتم العثور على الطالب',
        );
      }
      await docRef.delete();
      return const ApiResponse(
        success: true,
        message: 'تم حذف الطالب من الطابور',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر حذف الطالب: $e',
      );
    }
  }

  /// Action: Update Student Status in Firestore
  static Future<ApiResponse> updateStatus({
    required String studentId,
    required StudentStatus newStatus,
  }) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
      }

      final statusStr = newStatus.toCode();
      final updates = <String, dynamic>{
        'status': statusStr,
      };

      // Set calledTime if student is being called to service
      if (newStatus == StudentStatus.inProgress || newStatus == StudentStatus.inAdvising) {
        final docSnap = await docRef.get();
        final data = docSnap.data() as Map<String, dynamic>?;
        if (data == null || data['calledTime'] == null || data['calledTime'].toString().isEmpty) {
          updates['calledTime'] = _getCurrentTimestamp();
        }
      }

      await docRef.update(updates);

      return ApiResponse(
        success: true,
        message: 'تم تحديث حالة الطالب إلى ${newStatus.arabicLabel}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر تحديث حالة الطالب: ${e.toString()}',
      );
    }
  }

  /// Action: Promote Pending Papers to WAITING
  static Future<ApiResponse> setPaperReady(String studentId) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
      }

      await docRef.update({
        'status': StudentStatus.waiting.toCode(),
        'paperStatus': PaperStatus.ready.toCode(),
      });

      return ApiResponse(
        success: true,
        message: 'تم استكمال أوراق الطالب وترقيته لقائمة الانتظار',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر استكمال أوراق الطالب: ${e.toString()}',
      );
    }
  }

  /// Mark the shared materials-registration paper as printed.
  static Future<ApiResponse> setMaterialsPrinted(String studentId) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
      }
      await docRef.update({
        'materialsPrinted': true,
        'advisingTime': _getCurrentTimestamp(),
      });
      return const ApiResponse(success: true, message: 'تم تسجيل طباعة ورقة تسجيل المواد');
    } catch (e) {
      return ApiResponse(success: false, message: 'تعذر تسجيل الطباعة: $e');
    }
  }

  static Future<ApiResponse> finishDoctorService(String studentId) async {
      try {
        final docRef = await _findStudentDocRef(studentId);
        if (docRef == null) {
          return const ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
        }
        await docRef.update({
          'status': StudentStatus.waitingAdvising.toCode(),
          'materialsPrinted': false,
          'completionTime': _getCurrentTimestamp(),
        });
        return const ApiResponse(success: true, message: 'تم نقل الطالب إلى قائمة الطباعة');
      } catch (e) {
        return ApiResponse(success: false, message: 'تعذر إنهاء خدمة الدكتور: $e');
      }
    }

  static Future<ApiResponse> requeueStudent(String studentId) async {
      try {
        final docRef = await _findStudentDocRef(studentId);
        if (docRef == null) {
          return const ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
        }
        await docRef.update({
          'status': StudentStatus.waiting.toCode(),
          'registrationTime': _getCurrentTimestamp(),
          'calledTime': '',
        });
        return const ApiResponse(success: true, message: 'تمت إعادة الطالب إلى آخر الطابور');
      } catch (e) {
        return ApiResponse(success: false, message: 'تعذر إعادة الطالب للطابور: $e');
      }
    }

  static Future<ApiResponse> requeuePendingPapers(String studentId) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return const ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
      }
      await docRef.update({
        'status': StudentStatus.pendingPapers.toCode(),
        'registrationTime': _getCurrentTimestamp(),
      });
      return const ApiResponse(success: true, message: 'تمت إعادة الطالب إلى آخر قائمة انتظار الأوراق');
    } catch (e) {
      return ApiResponse(success: false, message: 'تعذر إعادة الطالب لقائمة الانتظار: $e');
    }
  }

  /// Action: Send Student to Academic Advising (IN_PROGRESS -> WAITING_ADVISING)
  static Future<ApiResponse> sendToAdvising(String studentId) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
      }
      final snapshot = await docRef.get();
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data?['materialsPrinted'] != true) {
        return const ApiResponse(
          success: false,
          message: 'لا يمكن تحويل الطالب قبل تسجيل طباعة ورقة تسجيل المواد',
        );
      }
      await docRef.update({'status': StudentStatus.waitingAdvising.toCode()});
      return const ApiResponse(success: true, message: 'تم تحويل الطالب إلى الإرشاد الأكاديمي');
    } catch (e) {
      return ApiResponse(success: false, message: 'تعذر تحويل الطالب للإرشاد: $e');
    }
  }

  /// Action: Complete Service (Moves student status to DONE or CANCELLED)
  static Future<ApiResponse> completeService(
    String studentId, {
    StudentStatus finalStatus = StudentStatus.done,
  }) async {
    try {
      final docRef = await _findStudentDocRef(studentId);
      if (docRef == null) {
        return ApiResponse(success: false, message: 'لم يتم العثور على الطالب في الفايربيس');
      }

      await docRef.update({
        'status': finalStatus.toCode(),
        'completionTime': _getCurrentTimestamp(),
      });

      return ApiResponse(
        success: true,
        message: 'تم إتمام خدمة الطالب ونقله لقائمة المكتملين',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر إتمام خدمة الطالب: ${e.toString()}',
      );
    }
  }
}
