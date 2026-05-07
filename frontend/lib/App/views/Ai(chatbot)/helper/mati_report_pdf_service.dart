import "dart:io";
import "dart:math" as math;

import "package:astro_tale/services/api_services/chatbot/chat_bot_services.dart";
import "package:open_filex/open_filex.dart";
import "package:path_provider/path_provider.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:shared_preferences/shared_preferences.dart";

// ─── Colours ─────────────────────────────────────────────────────────────────

class _C {
  static const brand = PdfColor(0.11, 0.31, 0.85);
  static const ink = PdfColor(0.06, 0.09, 0.16);
  static const body = PdfColor(0.20, 0.33, 0.45);
  static const muted = PdfColor(0.39, 0.45, 0.55);
  static const border = PdfColor(0.89, 0.91, 0.94);
  static const surface = PdfColor(0.97, 0.98, 0.99);
  static const white = PdfColors.white;

  static const success = PdfColor(0.09, 0.64, 0.29);
  static const successBg = PdfColor(0.94, 0.99, 0.96);
  static const warning = PdfColor(0.71, 0.33, 0.04);
  static const warningBg = PdfColor(1.00, 0.99, 0.92);
  static const danger = PdfColor(0.86, 0.15, 0.15);
  static const dangerBg = PdfColor(1.00, 0.95, 0.95);
  static const purple = PdfColor(0.49, 0.23, 0.93);
}

// ─── Text Styles ─────────────────────────────────────────────────────────────

class _T {
  static pw.TextStyle title() => pw.TextStyle(
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
    color: _C.ink,
    lineSpacing: 1.5,
  );

  static pw.TextStyle h1() => pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: _C.ink,
    lineSpacing: 1.4,
  );

  static pw.TextStyle h2() => pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: _C.ink,
    lineSpacing: 1.3,
  );

  static pw.TextStyle body() =>
      pw.TextStyle(fontSize: 10.5, color: _C.body, lineSpacing: 2.0);

  static pw.TextStyle small() =>
      pw.TextStyle(fontSize: 9.0, color: _C.muted, lineSpacing: 1.4);

  static pw.TextStyle smallBold() => pw.TextStyle(
    fontSize: 9.0,
    fontWeight: pw.FontWeight.bold,
    color: _C.muted,
    lineSpacing: 1.4,
  );

  static pw.TextStyle colored(PdfColor c, {bool bold = false}) => pw.TextStyle(
    fontSize: 10.5,
    color: c,
    lineSpacing: 1.6,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
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

  String get initials {
    final parts = displayName
        .split(RegExp(r"\s+"))
        .where((p) => p.isNotEmpty)
        .take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  String get detailsLine => <String>[
    if (zodiacSign.isNotEmpty) zodiacSign.toUpperCase(),
    if (birthDate.isNotEmpty) birthDate,
    if (birthTime.isNotEmpty) birthTime,
    if (birthPlace.isNotEmpty) birthPlace,
  ].join("   |   ");
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
    final pdf = pw.Document(
      title: report.title.isEmpty ? "Mati Report" : report.title,
      author: "AstroNexus Mati AI",
      creator: "AstroNexus",
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox() : _header(report),
        footer: _footer,
        build: (ctx) =>
            _buildAll(report: report, response: response, profile: profile),
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
  }) {
    final w = <pw.Widget>[];

    // 1. Title block
    w.add(_titleBlock(report, profile));
    w.add(_gap(16));
    w.add(_divider());
    w.add(_gap(14));

    // 2. Stats row
    w.add(_statsRow(report, response));
    w.add(_gap(16));
    w.add(_divider());
    w.add(_gap(14));

    // 3. Summary
    final summary = report.summary.isNotEmpty
        ? report.summary
        : response.answer;
    if (summary.isNotEmpty) {
      w.add(_sectionLabel("Executive Summary"));
      w.add(_gap(8));
      w.add(_bodyBlock(summary));
      w.add(_gap(16));
      w.add(_divider());
      w.add(_gap(14));
    }

    // 4. Analysis
    if (response.analysis != null) {
      w.add(_sectionLabel("Astro Score Analysis"));
      w.add(_gap(10));
      w.add(_analysisBlock(response.analysis!));
      w.add(_gap(16));
      w.add(_divider());
      w.add(_gap(14));
    }

    // 5. Timing
    if (response.timing != null && response.timing!.hasContent) {
      w.add(_sectionLabel("Timing Snapshot"));
      w.add(_gap(10));
      w.add(_timingBlock(response.timing!));
      w.add(_gap(16));
      w.add(_divider());
      w.add(_gap(14));
    }

    // 6. Detailed sections
    if (report.visibleSections.isNotEmpty) {
      w.add(_sectionLabel("Detailed Reading"));
      w.add(_gap(10));
      for (var i = 0; i < report.visibleSections.length; i++) {
        if (i > 0) w.add(_gap(10));
        w.add(_sectionBlock(report.visibleSections[i], i));
      }
    }

    // 7. Closing note
    w.add(_gap(20));
    w.add(_closingNote());

    return w;
  }

  // ── Title Block ────────────────────────────────────────────────────────────

  static pw.Widget _titleBlock(MatiReportData report, _Profile profile) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 52,
          height: 52,
          decoration: pw.BoxDecoration(
            color: _C.brand,
            shape: pw.BoxShape.circle,
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            profile.initials,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _C.white,
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("AstroNexus · Mati AI Reading", style: _T.small()),
              pw.SizedBox(height: 4),
              pw.Text(
                report.title.isEmpty ? "Mati Astrology Report" : report.title,
                style: _T.title(),
              ),
              if (report.subtitle.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(report.subtitle, style: _T.body()),
              ],
              pw.SizedBox(height: 6),
              if (profile.hasContent)
                pw.Text(
                  "Prepared for: ${profile.displayName}",
                  style: _T.colored(_C.brand, bold: true),
                ),
              if (profile.detailsLine.isNotEmpty)
                pw.Text(profile.detailsLine, style: _T.small()),
              if (report.generatedOn.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text("Generated: ${report.generatedOn}", style: _T.small()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────

  static pw.Widget _statsRow(MatiReportData report, MatiChatResponse response) {
    final items = <_StatItem>[
      _StatItem("Sections", report.sectionCount.toString(), _C.brand),
    ];

    if (response.analysis != null) {
      final s = response.analysis!.decisionScore;
      items.add(
        _StatItem(
          "Decision Score",
          "${s.toStringAsFixed(0)}%",
          s >= 70
              ? _C.success
              : s >= 50
              ? _C.warning
              : _C.danger,
        ),
      );
      items.add(
        _StatItem(
          "Positive",
          "${response.analysis!.positivePercentage.toStringAsFixed(0)}%",
          _C.success,
        ),
      );
      items.add(
        _StatItem(
          "Challenging",
          "${response.analysis!.negativePercentage.toStringAsFixed(0)}%",
          _C.danger,
        ),
      );
    }

    final favorable = response.timing?.favorableDates.length ?? 0;
    if (favorable > 0) {
      items.add(_StatItem("Good Dates", "$favorable", _C.success));
    }

    return pw.Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return pw.Expanded(
          child: pw.Container(
            margin: pw.EdgeInsets.only(left: i == 0 ? 0 : 8),
            padding: const pw.EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _C.border),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.label, style: _T.small()),
                pw.SizedBox(height: 4),
                pw.Text(
                  item.value,
                  style: pw.TextStyle(
                    fontSize: 15,
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
    final score = analysis.decisionScore;
    final positive = analysis.positivePercentage;
    final negative = analysis.negativePercentage;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _scoreRow(
          "Decision Confidence",
          score,
          score >= 70
              ? _C.success
              : score >= 50
              ? _C.warning
              : _C.danger,
        ),
        pw.SizedBox(height: 7),
        _scoreRow("Positive Influences", positive, _C.success),
        pw.SizedBox(height: 7),
        _scoreRow("Challenging Aspects", negative, _C.danger),
        if (analysis.planetBreakdown.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text("Planetary Highlights", style: _T.h2()),
          pw.SizedBox(height: 8),
          ...analysis.planetBreakdown.take(5).map(_planetRow),
        ],
      ],
    );
  }

  static pw.Widget _scoreRow(String label, double value, PdfColor color) {
    final pct = value.clamp(0.0, 100.0);
    // Usable bar width ≈ A4 width minus margins (515 - 80 = 435pt)
    const barMax = 435.0;
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
        pw.SizedBox(height: 4),
        pw.Stack(
          children: [
            pw.Container(
              height: 6,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: _C.border,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
            pw.Container(
              height: 6,
              width: barMax * (pct / 100),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _planetRow(MatiPlanetInsight planet) {
    final isPos = planet.isPositive;
    final color = isPos ? _C.success : _C.danger;
    final bgColor = isPos ? _C.successBg : _C.dangerBg;
    final sign = isPos ? "+" : "−";

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _C.border),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(planet.planet, style: _T.h2()),
                if (planet.reason.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(_clean(planet.reason), style: _T.body()),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            "$sign ${planet.strength.toStringAsFixed(0)}/10",
            style: _T.colored(color, bold: true),
          ),
        ],
      ),
    );
  }

  // ── Timing Block ───────────────────────────────────────────────────────────

  static pw.Widget _timingBlock(MatiTimingInfo timing) {
    final needsBirth = timing.requiresBirthData;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (needsBirth)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _C.warningBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _C.warning),
            ),
            child: pw.Text(
              "Note: Provide birth details for a more personalised timing reading.",
              style: _T.colored(_C.warning),
            ),
          ),
        if (timing.note.isNotEmpty) ...[
          if (needsBirth) pw.SizedBox(height: 10),
          ..._paragraphWidgets(_paragraphs(timing.note)),
        ],
        if (timing.favorableDates.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text("Favorable Dates", style: _T.h2()),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: timing.favorableDates
                .take(6)
                .map((d) => _chip(d, _C.success, _C.successBg))
                .toList(),
          ),
        ],
        if (timing.avoidDates.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text("Use Extra Care On", style: _T.h2()),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: timing.avoidDates
                .take(6)
                .map((d) => _chip(d, _C.danger, _C.dangerBg))
                .toList(),
          ),
        ],
      ],
    );
  }

  static pw.Widget _chip(MatiDateSuggestion d, PdfColor fg, PdfColor bg) {
    final parts = <String>[
      d.date,
      if (d.label.isNotEmpty) d.label,
      if (d.confidence.isNotEmpty) d.confidence,
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: fg),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(parts.join(" · "), style: _T.colored(fg, bold: true)),
    );
  }

  // ── Section Block ──────────────────────────────────────────────────────────

  static pw.Widget _sectionBlock(MatiReportSection section, int index) {
    final accent = index.isEven ? _C.brand : _C.purple;

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _C.border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: _C.surface,
              border: pw.Border(bottom: pw.BorderSide(color: _C.border)),
              // Remove borderRadius here, only bottom border is used
            ),
            child: pw.Row(
              children: [
                pw.Container(width: 3, height: 16, color: accent),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(section.heading, style: _T.h1())),
                pw.Text("${index + 1}", style: _T.colored(accent, bold: true)),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _paragraphWidgets(_paragraphs(section.content)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────

  static pw.Widget _sectionLabel(String text) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 16, color: _C.brand),
        pw.SizedBox(width: 8),
        pw.Text(text, style: _T.h1()),
      ],
    );
  }

  // ── Body Block ─────────────────────────────────────────────────────────────

  static pw.Widget _bodyBlock(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _paragraphWidgets(_paragraphs(text)),
    );
  }

  // ── Header / Footer ────────────────────────────────────────────────────────

  static pw.Widget _header(MatiReportData report) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _C.border)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            report.title.isEmpty ? "Mati Astrology Report" : report.title,
            style: _T.small(),
          ),
          pw.Text(
            "AstroNexus · Mati AI",
            style: _T.colored(_C.brand, bold: true),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _C.border)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "AstroNexus Mati AI · For personal guidance only",
            style: _T.small(),
          ),
          pw.Text(
            "Page ${ctx.pageNumber} of ${ctx.pagesCount}",
            style: _T.smallBold(),
          ),
        ],
      ),
    );
  }

  // ── Closing Note ───────────────────────────────────────────────────────────

  static pw.Widget _closingNote() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _C.surface,
        border: pw.Border.all(color: _C.border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        "This report was generated by AstroNexus Mati AI. "
        "It is intended for personal reflection and guidance only.",
        style: _T.small(),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ── Shared Helpers ─────────────────────────────────────────────────────────

  static pw.Widget _divider() => pw.Container(height: 0.8, color: _C.border);

  static pw.Widget _gap(double h) => pw.SizedBox(height: h);

  static List<pw.Widget> _paragraphWidgets(List<String> paragraphs) {
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
      if (i != paragraphs.length - 1) out.add(pw.SizedBox(height: 6));
    }
    return out;
  }

  // ── Text Processing ────────────────────────────────────────────────────────

  static List<String> _paragraphs(String raw) {
    final normalized = _clean(raw);
    if (normalized.isEmpty) return const [];

    final withHints = normalized.replaceAllMapped(
      RegExp(
        r"\s+(BirthDate:|BirthTime:|BirthPlace:|ZodiacSign:|Focus:|Timing tip:)",
      ),
      (m) => "\n${m.group(1)}",
    );

    final blocks = withHints
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
    final candidate = rawName.trim().isEmpty
        ? "mati_report.pdf"
        : rawName.trim();
    final sanitized = candidate.replaceAll(RegExp(r'[<>:"/\\|?*]+'), "-");
    return sanitized.toLowerCase().endsWith(".pdf")
        ? sanitized
        : "$sanitized.pdf";
  }
}
