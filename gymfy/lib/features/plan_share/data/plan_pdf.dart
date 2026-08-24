// Turning a plan into a printable page.
//
// Black on white, no accent colour, no logo. This is the sheet you fold into
// your gym bag or hand to someone at the rack — it has to survive a cheap
// printer and be readable at arm's length, and a dark theme rendered to paper
// would empty a toner cartridge to make something harder to read.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/utils/format.dart';
import '../../../shared/utils/weekday.dart';
import 'plan_document.dart';

/// Builds a printable version of [document].
Future<Uint8List> buildPlanPdf(PlanDocument document) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
      // MultiPage rather than Page: a six-day programme with ten lifts a day
      // runs past one sheet, and silently cropping the last day would be the
      // worst possible failure for a page you take to the gym.
      build: (context) => [
        for (final split in document.splits) ..._splitSection(split),
      ],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
    ),
  );

  return pdf.save();
}

List<pw.Widget> _splitSection(SharedSplit split) {
  return [
    pw.Header(
      level: 0,
      child: pw.Text(
        split.name,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
    ),
    for (final day in split.days) ...[
      // Kept with at least the start of its table, so a day's heading never
      // ends up stranded alone at the foot of a page.
      pw.SizedBox(height: 14),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            day.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            weekdaySummary(day.weekdays) ?? 'Not scheduled',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      if (day.exercises.isEmpty)
        pw.Text(
          'No exercises',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        )
      else
        _exerciseTable(day),
    ],
    pw.SizedBox(height: 20),
  ];
}

pw.Widget _exerciseTable(SharedDay day) {
  return pw.TableHelper.fromTextArray(
    cellAlignment: pw.Alignment.centerLeft,
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 10),
    // A printed plan is something you write on. The last column is left empty
    // on purpose: it's where the weights go in pencil.
    headers: const ['Exercise', 'Sets × reps', 'Warm-up', 'Weight'],
    columnWidths: const {
      0: pw.FlexColumnWidth(4),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(1.6),
    },
    cellHeight: 22,
    data: [
      for (final exercise in day.exercises)
        [
          exercise.name,
          pdfSafeTarget(exercise.sets, exercise.reps, exercise.repsMax),
          exercise.warmupSets == 0 ? '-' : '${exercise.warmupSets}',
          '',
        ],
    ],
  );
}

/// A set target the built-in PDF font can actually draw, e.g. `3 × 8-12`.
///
/// The screen version uses an en dash for ranges, which is right on screen and
/// invisible on paper: the PDF's built-in Helvetica has no Unicode support, so
/// "8–12" draws as "8 12" with a hole where the dash should be. A hyphen is
/// covered by the font's own encoding. The multiplication sign survives, so the
/// target still reads as one.
///
/// The alternative is embedding a Unicode font — hundreds of kilobytes of asset
/// to render one character a hyphen already covers on a printed sheet.
String pdfSafeTarget(int sets, int reps, int? repsMax) {
  return formatSetTarget(
    sets,
    reps,
    repsMax,
  ).replaceAll('–', '-').replaceAll('—', '-');
}
