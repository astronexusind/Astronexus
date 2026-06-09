import "dart:io";
import "dart:math" as math;
import "dart:typed_data";

import "package:astro_tale/services/api_services/chatbot/chat_bot_services.dart";
import "package:flutter/services.dart";
import "package:open_filex/open_filex.dart";
import "package:path_provider/path_provider.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:shared_preferences/shared_preferences.dart";

// ─── Colour Palette ──────────────────────────────────────────────────────────

class _C {
  // Brand
  static const ink     = PdfColor(0.08, 0.08, 0.12);       // near-black
  static const heading = PdfColor(0.12, 0.10, 0.28);       // deep indigo
  static const body    = PdfColor(0.25, 0.28, 0.38);       // dark slate
  static const muted   = PdfColor(0.48, 0.50, 0.58);       // grey

  // Layout
  static const rule    = PdfColor(0.87, 0.89, 0.94);       // light divider
  static const surface = PdfColor(0.97, 0.97, 0.99);       // off-white card bg
  static const white   = PdfColors.white;

  // Semantic (used sparingly)
  static const green   = PdfColor(0.10, 0.55, 0.28);
  static const greenBg = PdfColor(0.93, 0.98, 0.95);
  static const red     = PdfColor(0.80, 0.14, 0.14);
  static const redBg   = PdfColor(0.99, 0.94, 0.94);
  static const amber   = PdfColor(0.70, 0.42, 0.04);
  static const amberBg = PdfColor(1.00, 0.97, 0.88);
}

// ─── Text Styles ─────────────────────────────────────────────────────────────

class _T {
  static pw.TextStyle h1() => pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        color: _C.heading,
        lineSpacing: 1.5,
      );

  static pw.TextStyle h2() => pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _C.heading,
        lineSpacing: 1.4,
      );

  static pw.TextStyle h3() => pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _C.ink,
        lineSpacing: 1.3,
      );

  static pw.TextStyle body() =>
      pw.TextStyle(fontSize: 10, color: _C.body, lineSpacing: 1.8);

  static pw.TextStyle small() =>
      pw.TextStyle(fontSize: 8.5, color: _C.muted, lineSpacing: 1.4);

  static pw.TextStyle label() => pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _C.muted,
        letterSpacing: 0.8,
        lineSpacing: 1.2,
      );

  static pw.TextStyle colored(PdfColor c, {bool bold = false}) => pw.TextStyle(
        fontSize: 10,
        color: c,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        lineSpacing: 1.5,
      );
}

// ─── Internal Models ──────────────────────────────────────────────────────────

class _Profile {
  const _Profile({
    required this.userName,
    required this.zodiacSign,
    required this.birthDate,
    required this.birthTime,
    required this.birthPlace,
  });

  final String userName, zodiacSign, birthDate, birthTime, birthPlace;

  bool get hasContent =>
      userName.isNotEmpty ||
      zodiacSign.isNotEmpty ||
      birthDate.isNotEmpty ||
      birthTime.isNotEmpty ||
      birthPlace.isNotEmpty;

  String get displayName => userName.isEmpty ? "AstroNexus User" : userName;
}

class _StatItem {
  const _StatItem(this.label, this.value, this.color);
  final String label, value;
  final PdfColor color;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class MatiReportPdfService {
  const MatiReportPdfService._();

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<File> generatePdf(MatiChatResponse response) async {
    final report = response.report;
    if (report == null || !report.hasContent) {
      throw Exception("Report data is not available for PDF export.");
    }

    final profile = await _loadProfile();
    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load("assets/images/logo.png");
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    final pdf = pw.Document(
      title: report.title.isEmpty ? "Mati Report" : report.title,
      author: "AstroNexus · Mati AI",
      creator: "AstroNexus",
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 44),
        header: (ctx) =>
            ctx.pageNumber == 1 ? pw.SizedBox() : _header(report, logoBytes),
        footer: _footer,
        build: (ctx) => _buildAll(
          report: report,
          response: response,
          profile: profile,
          logoBytes: logoBytes,
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final name = _safeFileName(report.fileName);
    final file = File("${dir.path}/$name");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateAndOpen(MatiChatResponse response) async {
    final file = await generatePdf(response);
    await OpenFilex.open(file.path);
    return file;
  }

  // ── Build All ──────────────────────────────────────────────────────────────

  static List<pw.Widget> _buildAll({
    required MatiReportData report,
    required MatiChatResponse response,
    required _Profile profile,
    required Uint8List? logoBytes,
  }) {
    final w = <pw.Widget>[];

    // 1. Cover
    w.add(_cover(report, profile, logoBytes));
    w.add(_gap(24));
    w.add(_rule());
    w.add(_gap(20));

    // 2. Stats bar (only if analysis data)
    if (response.analysis != null) {
      w.add(_statsBar(response));
      w.add(_gap(20));
      w.add(_rule());
      w.add(_gap(20));
    }

    // 3. Summary
    final summary =
        report.summary.isNotEmpty ? report.summary : response.answer;
    if (summary.isNotEmpty) {
      w.add(_sectionHead("Executive Summary"));
      w.add(_gap(8));
      w.add(_bodyText(summary));
      w.add(_gap(22));
    }

    // 4. Analysis
    if (response.analysis != null) {
      w.add(_sectionHead("Astro Score Analysis"));
      w.add(_gap(10));
      w.add(_analysisBlock(response.analysis!));
      w.add(_gap(22));
    }

    // 5. Timing
    if (response.timing != null && response.timing!.hasContent) {
      w.add(_sectionHead("Timing Guidance"));
      w.add(_gap(8));
      w.add(_timingBlock(response.timing!));
      w.add(_gap(22));
    }

    // 6. Detailed sections
    if (report.visibleSections.isNotEmpty) {
      w.add(_sectionHead("Detailed Reading"));
      w.add(_gap(10));
      for (var i = 0; i < report.visibleSections.length; i++) {
        if (i > 0) w.add(_gap(10));
        w.add(_sectionCard(report.visibleSections[i], i + 1));
      }
    }

    // 7. Disclaimer
    w.add(_gap(28));
    w.add(_disclaimer());

    return w;
  }

  // ── Cover ──────────────────────────────────────────────────────────────────

  static pw.Widget _cover(
    MatiReportData report,
    _Profile profile,
    Uint8List? logoBytes,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top row: logo + brand label
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null)
              pw.Image(
                pw.MemoryImage(logoBytes),
                width: 40,
                height: 40,
              )
            else
              pw.Container(
                width: 40,
                height: 40,
                decoration: const pw.BoxDecoration(
                  color: _C.heading,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "A",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _C.white,
                  ),
                ),
              ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "AstroNexus",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _C.heading,
                  ),
                ),
                pw.Text("Mati AI · Vedic Astrology Reading", style: _T.small()),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(height: 0.8, color: _C.rule),
        pw.SizedBox(height: 20),

        // Title
        pw.Text(
          report.title.isEmpty ? "Astrology Report" : report.title,
          style: _T.h1(),
        ),
        if (report.subtitle.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(report.subtitle, style: _T.body()),
        ],
        pw.SizedBox(height: 16),

        // Meta info row
        pw.Row(
          children: [
            if (profile.displayName.isNotEmpty)
              _metaCell("Prepared for", profile.displayName),
            if (profile.birthDate.isNotEmpty) ...[
              pw.SizedBox(width: 24),
              _metaCell("Date of Birth", profile.birthDate),
            ],
            if (profile.birthPlace.isNotEmpty) ...[
              pw.SizedBox(width: 24),
              _metaCell("Place", profile.birthPlace),
            ],
            if (report.generatedOn.isNotEmpty) ...[
              pw.SizedBox(width: 24),
              _metaCell("Generated", report.generatedOn),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _metaCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: _T.label()),
        pw.SizedBox(height: 3),
        pw.Text(value, style: _T.colored(_C.heading, bold: true)),
      ],
    );
  }

  // ── Stats Bar ──────────────────────────────────────────────────────────────

  static pw.Widget _statsBar(MatiChatResponse response) {
    final a = response.analysis!;
    final s = a.decisionScore;
    final items = <_StatItem>[
      _StatItem(
        "COSMIC SCORE",
        "${s.toStringAsFixed(0)}%",
        s >= 70 ? _C.green : s >= 50 ? _C.amber : _C.red,
      ),
      _StatItem(
        "POSITIVE",
        "${a.positivePercentage.toStringAsFixed(0)}%",
        _C.green,
      ),
      _StatItem(
        "CHALLENGING",
        "${a.negativePercentage.toStringAsFixed(0)}%",
        _C.red,
      ),
    ];

    return pw.Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        return pw.Expanded(
          child: pw.Container(
            margin: pw.EdgeInsets.only(right: isLast ? 0 : 12),
            padding: const pw.EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            decoration: pw.BoxDecoration(
              color: _C.surface,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _C.rule),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.label, style: _T.label()),
                pw.SizedBox(height: 6),
                pw.Text(
                  item.value,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Analysis Block ─────────────────────────────────────────────────────────

  static pw.Widget _analysisBlock(MatiAnalysis analysis) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _progressRow(
          "Decision Confidence",
          analysis.decisionScore,
          analysis.decisionScore >= 70
              ? _C.green
              : analysis.decisionScore >= 50
                  ? _C.amber
                  : _C.red,
        ),
        pw.SizedBox(height: 10),
        _progressRow("Positive Influences", analysis.positivePercentage, _C.green),
        pw.SizedBox(height: 10),
        _progressRow("Challenging Aspects", analysis.negativePercentage, _C.red),
        if (analysis.planetBreakdown.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text("Planetary Highlights", style: _T.h3()),
          pw.SizedBox(height: 8),
          ...analysis.planetBreakdown.take(5).map(_planetRow),
        ],
      ],
    );
  }

  static pw.Widget _progressRow(
    String label,
    double value,
    PdfColor color,
  ) {
    final pct = value.clamp(0.0, 100.0);
    const barMax = 415.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: _T.body()),
            pw.Text(
              "${pct.toStringAsFixed(0)}%",
              style: _T.colored(color, bold: true),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Stack(
          children: [
            pw.Container(
              height: 6,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: _C.rule,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.Container(
              height: 6,
              width: barMax * (pct / 100),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _planetRow(MatiPlanetInsight planet) {
    final isPos = planet.isPositive;
    final color = isPos ? _C.green : _C.red;
    final bg = isPos ? _C.greenBg : _C.redBg;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(planet.planet, style: _T.h3()),
                if (planet.reason.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(_clean(planet.reason), style: _T.body()),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            "${isPos ? '+' : '−'}${planet.strength.toStringAsFixed(0)}/10",
            style: _T.colored(color, bold: true),
          ),
        ],
      ),
    );
  }

  // ── Timing Block ───────────────────────────────────────────────────────────

  static pw.Widget _timingBlock(MatiTimingInfo timing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (timing.note.isNotEmpty)
          pw.Text(_clean(timing.note), style: _T.body()),
        if (timing.favorableDates.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text("Favorable Dates", style: _T.h3()),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: timing.favorableDates
                .take(6)
                .map((d) => _dateChip(d, isGood: true))
                .toList(),
          ),
        ],
        if (timing.avoidDates.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text("Dates to Watch", style: _T.h3()),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: timing.avoidDates
                .take(6)
                .map((d) => _dateChip(d, isGood: false))
                .toList(),
          ),
        ],
      ],
    );
  }

  static pw.Widget _dateChip(MatiDateSuggestion d, {required bool isGood}) {
    final color = isGood ? _C.green : _C.red;
    final bg = isGood ? _C.greenBg : _C.redBg;
    final border = isGood
        ? const PdfColor(0.55, 0.85, 0.65)
        : const PdfColor(0.88, 0.55, 0.55);
    final text = [
      d.date,
      if (d.label.isNotEmpty) d.label,
    ].join(" · ");

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: _T.colored(color, bold: true)),
    );
  }

  // ── Section Card ───────────────────────────────────────────────────────────

  static pw.Widget _sectionCard(MatiReportSection section, int number) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _C.rule),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header row
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: _C.surface,
              border: pw.Border(
                bottom: pw.BorderSide(color: _C.rule),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  number.toString().padLeft(2, "0"),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _C.muted,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(section.heading, style: _T.h3()),
                ),
              ],
            ),
          ),
          // Content
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _paraWidgets(_paragraphs(section.content)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Section Utilities ────────────────────────────────────────────────

  static pw.Widget _sectionHead(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 3,
          height: 16,
          decoration: pw.BoxDecoration(
            color: _C.heading,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(text, style: _T.h2()),
      ],
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _paraWidgets(_paragraphs(text)),
    );
  }

  static pw.Widget _rule() =>
      pw.Container(height: 0.8, color: _C.rule);

  static pw.Widget _gap(double h) => pw.SizedBox(height: h);

  // ── Header / Footer ────────────────────────────────────────────────────────

  static pw.Widget _header(MatiReportData report, Uint8List? logoBytes) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _C.rule)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            report.title.isEmpty ? "Astrology Report" : report.title,
            style: _T.small(),
          ),
          pw.Row(
            children: [
              if (logoBytes != null)
                pw.Image(pw.MemoryImage(logoBytes), width: 16, height: 16),
              pw.SizedBox(width: 5),
              pw.Text(
                "AstroNexus",
                style: _T.colored(_C.heading, bold: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _C.rule)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "AstroNexus · For personal guidance only",
            style: _T.small(),
          ),
          pw.Text(
            "Page ${ctx.pageNumber} of ${ctx.pagesCount}",
            style: _T.small(),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────────

  static pw.Widget _disclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _C.surface,
        border: pw.Border.all(color: _C.rule),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        "This report is generated by AstroNexus Mati AI for personal reflection "
        "and spiritual guidance only. It does not constitute professional or medical advice.",
        style: _T.small(),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ── Text Helpers ───────────────────────────────────────────────────────────

  static List<pw.Widget> _paraWidgets(List<String> paragraphs) {
    if (paragraphs.isEmpty) return [pw.Text("", style: _T.body())];
    final out = <pw.Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      out.add(
        pw.Text(
          paragraphs[i],
          style: _T.body(),
          textAlign: pw.TextAlign.justify,
        ),
      );
      if (i != paragraphs.length - 1) out.add(pw.SizedBox(height: 7));
    }
    return out;
  }

  static List<String> _paragraphs(String raw) {
    final normalized = _clean(raw);
    if (normalized.isEmpty) return const [];

    final blocks = normalized
        .split(RegExp(r"\n+"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final result = <String>[];
    for (final block in blocks) {
      final sentences = block
          .split(RegExp(r"(?<=[.!?])\s+"))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (sentences.length <= 2 || block.contains(":")) {
        result.add(block);
        continue;
      }
      for (var i = 0; i < sentences.length; i += 2) {
        final end = math.min(i + 2, sentences.length);
        result.add(sentences.sublist(i, end).join(" "));
      }
    }
    return result;
  }

  static String _clean(String raw) => raw
      .replaceAll("\r\n", "\n")
      .replaceAllMapped(RegExp(r"[ \t]+"), (_) => " ")
      .replaceAllMapped(RegExp(r"\n\s*"), (_) => "\n")
      .replaceAll(RegExp(r"\s+\."), ".")
      .trim();

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<_Profile> _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    return _Profile(
      userName: (p.getString("userName") ?? "").trim(),
      zodiacSign: (p.getString("zodiacSign") ?? "").trim(),
      birthDate: (p.getString("birthDate") ?? "").trim(),
      birthTime: (p.getString("birthTime") ?? "").trim(),
      birthPlace: (p.getString("birthPlace") ?? "").trim(),
    );
  }

  static String _safeFileName(String rawName) {
    final candidate =
        rawName.trim().isEmpty ? "mati_report.pdf" : rawName.trim();
    final sanitized = candidate.replaceAll(RegExp(r'[<>:"/\\|?*]+'), "-");
    return sanitized.toLowerCase().endsWith(".pdf")
        ? sanitized
        : "$sanitized.pdf";
  }
}
