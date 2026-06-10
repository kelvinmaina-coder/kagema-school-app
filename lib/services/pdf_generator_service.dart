import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/school_models.dart';

class PdfGeneratorService {
  static Future<void> generateReportCard(Student student, List<Mark> marks, String term, int year, {String? remarks}) async {
    final pdf = pw.Document();

    double totalScore = marks.fold(0, (sum, item) => sum + item.score);
    double average = marks.isEmpty ? 0 : totalScore / marks.length;
    int totalPoints = marks.fold(0, (sum, item) => sum + item.points);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                          pw.Text('Motto: Excellence in Education', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                          pw.Text('P.O. Box 1234, Nairobi | Tel: +254 700 000 000', style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text('STUDENT PROGRESS REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                ),
                pw.Center(child: pw.Text('$term - $year Academic Year')),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('NAME: ${student.name.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('ADM NO: ${student.admissionNumber}'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('GRADE: ${student.grade}'),
                          pw.Text('STREAM: ${student.stream}'),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange),
                  headers: ['SUBJECT', 'SCORE', 'CODE', 'POINTS', 'ACHIEVEMENT LEVEL'],
                  data: marks.map((m) => [
                    m.subject,
                    m.score.toStringAsFixed(0),
                    _getGradingCode(m.score),
                    m.points.toString(),
                    m.achievementLevel,
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('TOTAL MARKS: ${totalScore.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('AVERAGE SCORE: ${average.toStringAsFixed(1)}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('TOTAL POINTS: $totalPoints', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('Teacher\'s Remarks (Auto-Generated Analysis):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Text(remarks ?? 'No remarks provided.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 11)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Principal\'s Signature: _______________________    Date: ________________________'),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text('This is a computer-generated report based on programmed academic logic.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Report_${student.admissionNumber}.pdf');
  }

  static Future<void> generateBulkReports(List<Student> students, Map<String, List<Mark>> studentMarks, String term, int year) async {
    final pdf = pw.Document();

    for (var student in students) {
      final marks = studentMarks[student.studentId] ?? [];
      double totalScore = marks.fold(0, (sum, item) => sum + item.score);
      double average = marks.isEmpty ? 0 : totalScore / marks.length;
      int totalPoints = marks.fold(0, (sum, item) => sum + item.points);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                            pw.Text('Motto: Excellence in Education', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                            pw.Text('P.O. Box 1234, Nairobi', style: pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(child: pw.Text('STUDENT PROGRESS REPORT CARD', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
                  pw.Center(child: pw.Text('$term - $year')),
                  pw.SizedBox(height: 20),
                  pw.Text('NAME: ${student.name.toUpperCase()}'),
                  pw.Text('ADM NO: ${student.admissionNumber}'),
                  pw.Text('GRADE: ${student.grade} ${student.stream}'),
                  pw.SizedBox(height: 20),
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: ['SUBJECT', 'SCORE', 'POINTS', 'LEVEL'],
                    data: marks.map((m) => [m.subject, m.score.toString(), m.points.toString(), m.achievementLevel]).toList(),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('TOTAL: $totalScore | AVG: ${average.toStringAsFixed(1)}% | POINTS: $totalPoints', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Bulk_Reports.pdf');
  }

  static Future<void> generateReceipt(Map<String, dynamic> payment) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('KAGEMA COMPREHENSIVE SCHOOL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
                pw.Center(child: pw.Text('OFFICIAL FEE RECEIPT', style: pw.TextStyle(fontSize: 12, decoration: pw.TextDecoration.underline))),
                pw.SizedBox(height: 20),
                pw.Text('Receipt No: ${payment['receiptNumber']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${payment['paymentDate']}'),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('Student Name: ${payment['studentName']}'),
                pw.Text('Term: ${payment['term']}'),
                pw.Text('Payment Method: ${payment['paymentMethod']}'),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('AMOUNT PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ksh ${payment['amountPaid']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Thank you for your payment.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text('This is a computer-generated receipt.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Receipt_${payment['receiptNumber']}.pdf');
  }

  static String _getGradingCode(double score) {
    if (score >= 90) return 'EE1';
    if (score >= 75) return 'EE2';
    if (score >= 58) return 'ME1';
    if (score >= 41) return 'ME2';
    if (score >= 31) return 'AE1';
    if (score >= 21) return 'AE2';
    if (score >= 11) return 'BE1';
    return 'BE2';
  }
}
