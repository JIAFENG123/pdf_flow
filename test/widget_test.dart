import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_flow/main.dart';

void main() {
  testWidgets('PdfFlowApp pump test', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfFlowApp());
    expect(find.text('PdfFlow'), findsOneWidget);
  });
}
