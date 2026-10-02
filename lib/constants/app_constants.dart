import 'package:flutter/material.dart';

/// Doctor List as specified in requirements
const List<String> kDoctorsList = [
  "أ. ابتهال",
  "أ. عبير",
  "أ. إحسان",
  "أ. نشوة",
  "أ. سوما",
  "أ. منى",
  "أ. منال",
];

/// Academic Advising entity identifier name
const String kAdvisingEntityName = "الإرشاد الأكاديمي";

/// Default Web App Script URL (user can edit in settings dialog)
const String kDefaultScriptUrl = "";

/// Universal String Normalization for Doctor/Entity matching:
/// Removes leading/trailing spaces, collapses multiple whitespace,
/// and normalizes Arabic character variations (أ, إ, آ -> ا).
String normalizeName(String name) {
  return name
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');
}

/// Safe comparison for doctor names ignoring spaces and alef variants
bool isDoctorMatch(String doc1, String doc2) {
  if (doc1.trim().isEmpty || doc2.trim().isEmpty) return false;
  return normalizeName(doc1) == normalizeName(doc2);
}

/// Student Status Enum
enum StudentStatus {
  pendingPapers,
  waiting,
  inProgress,
  waitingAdvising,
  inAdvising,
  done,
  cancelled,
}

/// Helper methods for StudentStatus
extension StudentStatusExtension on StudentStatus {
  String toCode() {
    switch (this) {
      case StudentStatus.pendingPapers:
        return 'PENDING_PAPERS';
      case StudentStatus.waiting:
        return 'WAITING';
      case StudentStatus.inProgress:
        return 'IN_PROGRESS';
      case StudentStatus.waitingAdvising:
        return 'WAITING_ADVISING';
      case StudentStatus.inAdvising:
        return 'IN_ADVISING';
      case StudentStatus.done:
        return 'DONE';
      case StudentStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static StudentStatus fromCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.contains('PENDING_PAPERS') || code.contains('ناقصة') || code.contains('معلقة')) {
      return StudentStatus.pendingPapers;
    }
    if (code.contains('WAITING_ADVISING') || code.contains('في انتظار الإرشاد') || code.contains('تحويل للإرشاد')) {
      return StudentStatus.waitingAdvising;
    }
    if (code.contains('IN_ADVISING') || code == 'في الإرشاد' || code == 'في الإرشاد الأكاديمي') {
      return StudentStatus.inAdvising;
    }
    if (code.contains('IN_PROGRESS') || code.contains('جاري') || code.contains('الخدمة')) {
      return StudentStatus.inProgress;
    }
    if (code.contains('WAITING') || code.contains('انتظار')) {
      return StudentStatus.waiting;
    }
    if (code.contains('DONE') || code.contains('مكتمل') || code.contains('تمت')) {
      return StudentStatus.done;
    }
    if (code.contains('CANCEL') || code.contains('ملغي')) {
      return StudentStatus.cancelled;
    }
    return StudentStatus.waiting;
  }

  String get arabicLabel {
    switch (this) {
      case StudentStatus.pendingPapers:
        return 'أوراق ناقصة';
      case StudentStatus.waiting:
        return 'في الانتظار';
      case StudentStatus.inProgress:
        return 'جاري الخدمة';
      case StudentStatus.waitingAdvising:
        return 'في انتظار الإرشاد';
      case StudentStatus.inAdvising:
        return 'في الإرشاد الأكاديمي';
      case StudentStatus.done:
        return 'تمت الخدمة';
      case StudentStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case StudentStatus.pendingPapers:
        return const Color(0xFFF59E0B); // Amber / Orange
      case StudentStatus.waiting:
        return const Color(0xFF3B82F6); // Blue
      case StudentStatus.inProgress:
        return const Color(0xFF10B981); // Emerald / Green
      case StudentStatus.waitingAdvising:
        return const Color(0xFF8B5CF6); // Purple
      case StudentStatus.inAdvising:
        return const Color(0xFFEC4899); // Pink
      case StudentStatus.done:
        return const Color(0xFF059669); // Dark Green
      case StudentStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case StudentStatus.pendingPapers:
        return Icons.pending_actions_rounded;
      case StudentStatus.waiting:
        return Icons.hourglass_top_rounded;
      case StudentStatus.inProgress:
        return Icons.record_voice_over_rounded;
      case StudentStatus.waitingAdvising:
        return Icons.next_plan_rounded;
      case StudentStatus.inAdvising:
        return Icons.psychology_rounded;
      case StudentStatus.done:
        return Icons.check_circle_rounded;
      case StudentStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}

/// Paper Status Enum
enum PaperStatus {
  ready,
  pending,
}

extension PaperStatusExtension on PaperStatus {
  String toCode() {
    switch (this) {
      case PaperStatus.ready:
        return 'READY';
      case PaperStatus.pending:
        return 'PENDING';
    }
  }

  static PaperStatus fromCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code == 'READY' || code == 'جاهزة' || code == 'مكتملة') {
      return PaperStatus.ready;
    }
    return PaperStatus.pending;
  }

  String get arabicLabel {
    switch (this) {
      case PaperStatus.ready:
        return 'جاهزة';
      case PaperStatus.pending:
        return 'ناقصة / معلقة';
    }
  }
}
