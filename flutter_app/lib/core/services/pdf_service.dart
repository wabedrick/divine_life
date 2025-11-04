import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFService {
  static Future<void> generateReportPDF({
    required Map<String, dynamic> report,
    required String reportType,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? charts,
  }) async {
    final pdf = pw.Document();

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(report, reportType),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildReportContent(report, reportType),
          if (stats != null) ..._buildStatsSection(stats),
          if (charts != null) ..._buildChartsSection(charts),
        ],
      ),
    );

    // Show print/save dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Divine_Life_Church_${reportType}_Report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static pw.Widget _buildHeader(
    Map<String, dynamic> report,
    String reportType,
  ) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'DIVINE LIFE CHURCH',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${reportType.toUpperCase()} REPORT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          if (report['week_of'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Week of: ${report['week_of']}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
          if (report['month'] != null && report['year'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Period: ${report['month']} ${report['year']}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Generated on ${DateTime.now().toString().split(' ')[0]} - Page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _buildReportContent(
    Map<String, dynamic> report,
    String reportType,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Basic Report Information
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Report Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildTableRow(
                    'Submitted by:',
                    report['submitted_by_name'] ?? 'N/A',
                  ),
                  if (report['mc_name'] != null)
                    _buildTableRow('Missional Community:', report['mc_name']),
                  if (report['branch_name'] != null)
                    _buildTableRow('Branch:', report['branch_name']),
                  _buildTableRow(
                    'Status:',
                    report['status']?.toString().toUpperCase() ?? 'N/A',
                  ),
                  _buildTableRow(
                    'Submitted on:',
                    report['created_at'] ?? 'N/A',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Attendance Information
        if (report['members_met'] != null || report['new_members'] != null) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attendance & Membership',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    if (report['members_met'] != null)
                      _buildTableRow(
                        'Members Met:',
                        report['members_met'].toString(),
                      ),
                    if (report['new_members'] != null)
                      _buildTableRow(
                        'New Members:',
                        report['new_members'].toString(),
                      ),
                    if (report['total_attendance'] != null)
                      _buildTableRow(
                        'Total Attendance:',
                        report['total_attendance'].toString(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Financial Information
        if (report['offerings'] != null ||
            report['total_offerings'] != null) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Financial Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    if (report['offerings'] != null)
                      _buildTableRow(
                        'Weekly Offerings:',
                        'UGX ${report['offerings']}',
                      ),
                    if (report['total_offerings'] != null)
                      _buildTableRow(
                        'Total Offerings:',
                        'UGX ${report['total_offerings']}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Activities and Comments
        if (report['evangelism_activities'] != null ||
            report['comments'] != null) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Activities & Comments',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (report['evangelism_activities'] != null) ...[
                  pw.Text(
                    'Evangelism Activities:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(report['evangelism_activities']),
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (report['comments'] != null) ...[
                  pw.Text(
                    'Comments:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(report['comments']),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildStatsSection(Map<String, dynamic> stats) {
    return [
      pw.SizedBox(height: 20),
      pw.Text(
        'Statistics Summary',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          if (stats['total_members'] != null)
            _buildTableRow('Total Members:', stats['total_members'].toString()),
          if (stats['total_attendance'] != null)
            _buildTableRow(
              'Total Attendance:',
              stats['total_attendance'].toString(),
            ),
          if (stats['total_offerings'] != null)
            _buildTableRow(
              'Total Offerings:',
              'UGX ${stats['total_offerings']}',
            ),
          if (stats['average_attendance'] != null)
            _buildTableRow(
              'Average Attendance:',
              stats['average_attendance'].toString(),
            ),
          if (stats['growth_percentage'] != null)
            _buildTableRow('Growth Rate:', '${stats['growth_percentage']}%'),
        ],
      ),
    ];
  }

  static List<pw.Widget> _buildChartsSection(
    List<Map<String, dynamic>> charts,
  ) {
    // Note: For charts, you would need to convert your fl_chart widgets to PDF-compatible format
    // This is a placeholder - actual implementation would require chart data conversion
    return [
      pw.SizedBox(height: 20),
      pw.Text(
        'Charts and Graphs',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Text(
          'Charts would be rendered here in a full implementation.\nThis requires converting chart data to PDF-compatible format.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ),
    ];
  }

  static Future<void> generateMonthlyReportPDF({
    required List<Map<String, dynamic>> reports,
    required String month,
    required String year,
    Map<String, dynamic>? monthlyStats,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildMonthlyHeader(month, year),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildMonthlySummary(reports, monthlyStats),
          pw.SizedBox(height: 20),
          ..._buildMonthlyReportsList(reports),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Divine_Life_Church_Monthly_Report_${month}_$year',
    );
  }

  static pw.Widget _buildMonthlyHeader(String month, String year) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'DIVINE LIFE CHURCH',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'MONTHLY REPORT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('$month $year', style: const pw.TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  static pw.Widget _buildMonthlySummary(
    List<Map<String, dynamic>> reports,
    Map<String, dynamic>? stats,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow(
              'Total Reports Submitted:',
              reports.length.toString(),
            ),
            _buildTableRow(
              'Approved Reports:',
              reports.where((r) => r['status'] == 'approved').length.toString(),
            ),
            _buildTableRow(
              'Pending Reports:',
              reports.where((r) => r['status'] == 'pending').length.toString(),
            ),
            if (stats != null) ...[
              if (stats['total_attendance'] != null)
                _buildTableRow(
                  'Total Monthly Attendance:',
                  stats['total_attendance'].toString(),
                ),
              if (stats['total_offerings'] != null)
                _buildTableRow(
                  'Total Monthly Offerings:',
                  'UGX ${stats['total_offerings']}',
                ),
            ],
          ],
        ),
      ],
    );
  }

  static List<pw.Widget> _buildMonthlyReportsList(
    List<Map<String, dynamic>> reports,
  ) {
    return [
      pw.Text(
        'Individual Reports',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 10),
      ...reports
          .take(10)
          .map<pw.Widget>(
            (report) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Week of: ${report['week_of'] ?? 'N/A'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        report['status']?.toString().toUpperCase() ?? 'N/A',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: report['status'] == 'approved'
                              ? PdfColors.green
                              : PdfColors.orange,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('MC: ${report['mc_name'] ?? 'N/A'}'),
                  pw.Text('Members Met: ${report['members_met'] ?? 'N/A'}'),
                  if (report['offerings'] != null)
                    pw.Text('Offerings: UGX ${report['offerings']}'),
                ],
              ),
            ),
          ),
    ];
  }
}
