import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/school_models.dart';
import 'package:intl/intl.dart';

class PdfGeneratorService {
  static Future<void> generateReportCard(Student student, List<Mark> marks, String term, int year, {String? remarks}) async {
    final pdf = pw.Document();
    double totalScore = marks.fold(0, (sum, item) => sum + item.score);
    double average = marks.isEmpty ? 0 : totalScore / marks.length;
    int totalPoints = marks.fold(0, (sum, item) => sum + item.points);

    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) {
      return pw.Padding(padding: const pw.EdgeInsets.all(20), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)), pw.Text('Motto: Excellence in Education', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)), pw.Text('P.O. Box 1234, Nairobi | Tel: +254 700 000 000', style: pw.TextStyle(fontSize: 10))])])),
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text('STUDENT PROGRESS REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
        pw.Center(child: pw.Text('$term - $year Academic Year')),
        pw.SizedBox(height: 30),
        pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('NAME: ${student.name.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('ADM NO: ${student.admissionNumber}')]), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('GRADE: ${student.grade}'), pw.Text('STREAM: ${student.stream}')])])),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(context: context, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange), headers: ['SUBJECT', 'SCORE', 'POINTS', 'ACHIEVEMENT LEVEL'], data: marks.map((m) => [m.subject, m.score.toStringAsFixed(0), m.points.toString(), m.achievementLevel]).toList()),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text('TOTAL MARKS: ${totalScore.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('AVERAGE SCORE: ${average.toStringAsFixed(1)}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('TOTAL POINTS: $totalPoints', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]))]),
        pw.Spacer(),
        pw.Center(child: pw.Text('This is a computer-generated report card.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Report_${student.admissionNumber}.pdf');
  }

  static Future<void> generateReceipt(Map<String, dynamic> payment) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a5, build: (pw.Context context) {
      return pw.Padding(padding: const pw.EdgeInsets.all(20), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange))),
        pw.Center(child: pw.Text('OFFICIAL FEE RECEIPT', style: pw.TextStyle(fontSize: 12, decoration: pw.TextDecoration.underline, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.TextDirection.ltr == pw.TextDirection.ltr ? pw.MainAxisAlignment.spaceBetween : pw.MainAxisAlignment.start, children: [pw.Text('Receipt No: ${payment['receipt_number'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Date: ${payment['payment_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now())}')]),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 10),
        pw.Text('Student Name: ${payment['student_name'] ?? 'Unknown'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Amount Paid: Ksh ${payment['amount_paid']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.Spacer(),
        pw.Center(child: pw.Text('Thank you for your payment.', style: pw.TextStyle(fontSize: 8))),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Receipt_${payment['receipt_number']}.pdf');
  }

  static Future<void> generatePayslip(Map<String, dynamic> staff, String monthYear) async {
    final pdf = pw.Document();
    final double salary = (staff['salary'] as num? ?? 0.0).toDouble();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) {
      return pw.Padding(padding: const pw.EdgeInsets.all(40), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo))),
        pw.Center(child: pw.Text('OFFICIAL SALARY ADVICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text('Pay Period: $monthYear')),
        pw.SizedBox(height: 40),
        pw.Text('Name: ${staff['name'] ?? 'N/A'}'),
        pw.Text('Designation: ${staff['role'] ?? 'Staff'}'),
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('NET PAYABLE:'), pw.Text('Ksh ${NumberFormat("#,##0").format(salary)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
        pw.Spacer(),
        pw.Center(child: pw.Text('This is an auto-generated document.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Payslip_${staff['name']}.pdf');
  }

  static Future<void> generateStudentList(List<Map<String, dynamic>> students) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4.landscape, build: (pw.Context context) {
      return pw.Padding(padding: const pw.EdgeInsets.all(20), child: pw.Column(children: [
        pw.Text('KAGEMA COMPREHENSIVE SCHOOL: OFFICIAL STUDENT REGISTRY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
          headers: ['NAME', 'ADM NO', 'GRADE', 'STREAM', 'GUARDIAN', 'PHONE'],
          data: students.map((s) => [s['name'], s['admission_number'], s['grade'], s['stream'], s['parent_name'], s['parent_phone']]).toList(),
        ),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Student_Registry.pdf');
  }

  static Future<void> generateVisitorLog(List<Map<String, dynamic>> visitors) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) {
      return pw.Padding(padding: const pw.EdgeInsets.all(20), child: pw.Column(children: [
        pw.Text('KAGEMA COMPREHENSIVE SCHOOL: VISITOR LOG', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
          headers: ['DATE', 'VISITOR NAME', 'CONTACT', 'PURPOSE'],
          data: visitors.map((v) => [v['date'], v['name'], v['phone'], v['purpose']]).toList(),
        ),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Visitor_Log.pdf');
  }

  static Future<void> generateFeeStructure(List<Map<String, dynamic>> structure, String academicYear) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) {
      return pw.Padding(padding: const pw.EdgeInsets.all(30), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Column(children: [pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)), pw.Text('OFFICIAL FEE STRUCTURE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)), pw.Text('Academic Year: $academicYear', style: pw.TextStyle(fontSize: 12)), pw.SizedBox(height: 20)])),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
          headers: ['GRADE/CLASS', 'TERMLY FEE (Ksh)', 'ANNUAL TOTAL (Ksh)'],
          data: structure.map((item) {
            double termly = (item['total_fee'] as num? ?? 0.0).toDouble();
            return [item['grade'] ?? 'N/A', NumberFormat("#,##0").format(termly), NumberFormat("#,##0").format(termly * 3)];
          }).toList(),
          cellAlignment: pw.Alignment.center,
        ),
        pw.Spacer(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Issued by: School Management', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)), pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8))]),
      ]));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Fee_Structure_$academicYear.pdf');
  }
}
