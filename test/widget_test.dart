import 'package:flutter_test/flutter_test.dart';
import 'package:fayoum_student_queue/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudentQueueApp());

    // Verify app title exists
    expect(find.text('نظام إدارة طابور الطلاب'), findsWidgets);
  });
}
