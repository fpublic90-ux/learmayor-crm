import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/intern.dart';

class PdfService {
  static Future<void> generateExecutiveSummary({
    required String companyName,
    required List<Employee> employees,
    required List<Intern> interns,
    required int todayAttendance,
    required List<MapEntry<String, int>> departments,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final totalStaff = employees.length + interns.length;
    final totalSalary = employees.fold<double>(0, (sum, e) => sum + e.salary);
    final totalStipend = interns.fold<double>(0, (sum, i) => sum + i.stipend);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', locale: 'en_IN', decimalDigits: 0);

    // Load custom font for better look if needed, or use standard
    final font = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(companyName.toUpperCase(),
                      style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.blue900)),
                  pw.Text('Executive Summary Report',
                      style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date: $dateStr', style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.Text('Confidential', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.red700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Divider(thickness: 2, color: PdfColors.blue800),
          pw.SizedBox(height: 30),

          // Overview Section
          pw.Text('1. Workforce Overview', style: pw.TextStyle(font: boldFont, fontSize: 18)),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('Total Employees', employees.length.toString(), font, boldFont),
              _buildStatBox('Active Interns', interns.length.toString(), font, boldFont),
              _buildStatBox('Present Today', todayAttendance.toString(), font, boldFont),
            ],
          ),
          pw.SizedBox(height: 40),

          // Financial Summary
          pw.Text('2. Financial Commitment (Monthly Estimate)', style: pw.TextStyle(font: boldFont, fontSize: 18)),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            data: <List<String>>[
              ['Category', 'Amount'],
              ['Employee Salaries', currencyFormat.format(totalSalary)],
              ['Intern Stipends', currencyFormat.format(totalStipend)],
              ['Total Monthly Payout', currencyFormat.format(totalSalary + totalStipend)],
            ],
          ),
          pw.SizedBox(height: 40),

          // Department Distribution
          pw.Text('3. Department Distribution', style: pw.TextStyle(font: boldFont, fontSize: 18)),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            data: <List<String>>[
              ['Department Name', 'Count', 'Percentage'],
              ...departments.map((e) => [
                    e.key,
                    e.value.toString(),
                    '${((e.value / totalStaff) * 100).toStringAsFixed(1)}%'
                  ]),
            ],
          ),
          
          pw.SizedBox(height: 60),
          pw.Center(
            child: pw.Text('End of Report', 
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500)),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Learnyor_Executive_Summary_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildStatBox(String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
