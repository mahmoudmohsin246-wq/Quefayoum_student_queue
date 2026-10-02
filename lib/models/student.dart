import '../constants/app_constants.dart';

class Student {
  final String id;
  final String name;
  final String nationalId;
  final bool materialsPrinted;
  final String doctor;
  final StudentStatus status;
  final PaperStatus paperStatus;
  final String registrationTime;
  final String calledTime;
  final String completionTime;
  final String advisingTime;

  Student({
    required this.id,
    required this.name,
    this.nationalId = '',
    this.materialsPrinted = false,
    required this.doctor,
    required this.status,
    required this.paperStatus,
    required this.registrationTime,
    this.calledTime = '',
    this.completionTime = '',
    this.advisingTime = '',
  });

  /// Factory constructor to convert JSON map from Apps Script API to Student model
  /// Supports flexible key mapping for Google Sheets headers (e.g., 'Student Name', 'Doctor', 'Status')
  factory Student.fromJson(Map<String, dynamic> json) {
    String getVal(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null && json[key].toString().trim().isNotEmpty) {
          return json[key].toString().trim();
        }
      }
      // Case-insensitive lookup fallback
      for (final key in keys) {
        for (final entry in json.entries) {
          if (entry.key.toString().trim().toLowerCase() == key.toLowerCase() &&
              entry.value != null &&
              entry.value.toString().trim().isNotEmpty) {
            return entry.value.toString().trim();
          }
        }
      }
      return '';
    }

    final id = getVal(['id', 'ID', 'Id', 'studentId', 'Student ID', 'المعرف']);
    final name = getVal(['name', 'Name', 'Student Name', 'studentName', 'اسم الطالب', 'الاسم']);
    final nationalId = getVal(['nationalId', 'national_id', 'National ID', 'الرقم القومي', 'الرقم القومى']);
    final materialsPrintedValue = getVal([
      'materialsPrinted',
      'materials_printed',
      'registrationPaperPrinted',
      'تمت طباعة ورقة تسجيل المواد',
    ]);
    final doctor = getVal(['doctor', 'Doctor', 'Doctor Name', 'doctorName', 'الدكتور', 'المشرف']);
    final statusStr = getVal(['status', 'Status', 'الحالة']);
    final paperStatusStr = getVal(['paperStatus', 'Paper Status', 'PaperStatus', 'paper_status', 'حالة الأوراق']);
    final registrationTime = getVal(['registrationTime', 'Registration Time', 'RegistrationTime', 'registration_time', 'وقت التسجيل']);
    final calledTime = getVal(['calledTime', 'Called Time', 'CalledTime', 'called_time', 'وقت الاستدعاء']);
    final completionTime = getVal(['completionTime', 'Completion Time', 'CompletionTime', 'completion_time', 'وقت الإتمام']);
    final advisingTime = getVal(['advisingTime', 'Advising Time', 'advising_time', 'وقت دخول الإرشاد']);

    return Student(
      id: id,
      name: name,
      nationalId: nationalId,
      materialsPrinted: materialsPrintedValue.toLowerCase() == 'true' ||
          materialsPrintedValue == '1' ||
          materialsPrintedValue == 'نعم',
      doctor: doctor,
      status: StudentStatusExtension.fromCode(statusStr.isEmpty ? 'WAITING' : statusStr),
      paperStatus: PaperStatusExtension.fromCode(paperStatusStr.isEmpty ? 'READY' : paperStatusStr),
      registrationTime: registrationTime,
      calledTime: calledTime,
      completionTime: completionTime,
      advisingTime: advisingTime,
    );
  }

  /// Convert Student model to JSON map for API payloads
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nationalId': nationalId,
      'materialsPrinted': materialsPrinted,
      'doctor': doctor,
      'status': status.toCode(),
      'paperStatus': paperStatus.toCode(),
      'registrationTime': registrationTime,
      'calledTime': calledTime,
      'completionTime': completionTime,
      'advisingTime': advisingTime,
    };
  }

  /// Copy helper method for state updates
  Student copyWith({
    String? id,
    String? name,
    String? nationalId,
    bool? materialsPrinted,
    String? doctor,
    StudentStatus? status,
    PaperStatus? paperStatus,
    String? registrationTime,
    String? calledTime,
    String? completionTime,
    String? advisingTime,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      nationalId: nationalId ?? this.nationalId,
      materialsPrinted: materialsPrinted ?? this.materialsPrinted,
      doctor: doctor ?? this.doctor,
      status: status ?? this.status,
      paperStatus: paperStatus ?? this.paperStatus,
      registrationTime: registrationTime ?? this.registrationTime,
      calledTime: calledTime ?? this.calledTime,
      completionTime: completionTime ?? this.completionTime,
      advisingTime: advisingTime ?? this.advisingTime,
    );
  }

  @override
  String toString() {
    return 'Student(id: $id, name: $name, doctor: $doctor, status: ${status.toCode()}, paperStatus: ${paperStatus.toCode()})';
  }
}
