import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_html.dart';

import '../constants/app_constants.dart';
import '../models/student.dart';

class ExcelExportService {
  /// Generate and export Excel (.xlsx) file containing completed students only.
  static Future<void> exportQueueToExcel({
    required List<Student> completedStudents,
  }) async {
    final excel = Excel.createExcel();

    // Default sheet name created by package is 'Sheet1'
    final defaultSheet = excel.getDefaultSheet();

    const completedSheetName = "المكتمل";

    final Sheet completedSheet = excel[completedSheetName];

    if (defaultSheet != null && defaultSheet != completedSheetName) {
      excel.delete(defaultSheet);
    }

    // Header columns in Arabic
    final headers = [
      TextCellValue('الرقم التسلسلي'),
      TextCellValue('اسم الطالب'),
      TextCellValue('الرقم القومي'),
      TextCellValue('الدكتور / المشرف'),
      TextCellValue('الحالة'),
      TextCellValue('حالة الأوراق'),
      TextCellValue('وقت التسجيل'),
      TextCellValue('وقت الاستدعاء'),
      TextCellValue('وقت الإتمام'),
    ];

    completedSheet.appendRow(headers);
    for (final student in completedStudents) {
      completedSheet.appendRow([
        TextCellValue(student.id),
        TextCellValue(student.name),
        TextCellValue(student.nationalId),
        TextCellValue(student.doctor),
        TextCellValue(student.status.arabicLabel),
        TextCellValue(student.paperStatus.arabicLabel),
        TextCellValue(student.registrationTime),
        TextCellValue(student.calledTime),
        TextCellValue(student.completionTime),
      ]);
    }

    // Encode Excel to bytes
    final fileBytes = excel.save();
    if (fileBytes == null || fileBytes.isEmpty) {
      throw Exception('فشل إنشاء ملف الإكسل (بيانات فارغة)');
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = 'queue_export_$dateStr.xlsx';

    if (kIsWeb) {
      triggerWebDownload(fileBytes, fileName);
    } else {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(fileBytes),
            name: fileName,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'تصدير طابور الطلاب ($fileName)',
        text: 'ملف الإكسل المصدّر لطابور الطلاب بتاريخ $dateStr',
      );
    }
  }
}
