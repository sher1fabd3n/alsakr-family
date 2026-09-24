import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

class PrivateDriverDeclarationData {
  final int studentId;
  String studentName;
  String grade;
  String stage;
  String academicYear;
  String driverName;
  String driverPhone;
  String driverNationalId;
  String parentName;
  String parentPhone;
  String relationship;

  PrivateDriverDeclarationData({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.stage,
    required this.academicYear,
    required this.driverName,
    required this.driverPhone,
    required this.driverNationalId,
    required this.parentName,
    required this.parentPhone,
    required this.relationship,
  });
}

class PrivateDriverDeclarationScreen extends StatefulWidget {
  const PrivateDriverDeclarationScreen({super.key, required this.initial});

  final PrivateDriverDeclarationData initial;

  @override
  State<PrivateDriverDeclarationScreen> createState() => _PrivateDriverDeclarationScreenState();
}

class _PrivateDriverDeclarationScreenState extends State<PrivateDriverDeclarationScreen> {
  late final TextEditingController _studentName;
  late final TextEditingController _stage;
  late final TextEditingController _grade;
  late final TextEditingController _year;
  late final TextEditingController _driverName;
  late final TextEditingController _driverPhone;
  late final TextEditingController _driverNationalId;
  late final TextEditingController _parentName;
  late final TextEditingController _relationship;
  late final TextEditingController _parentPhone;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _studentName = TextEditingController(text: d.studentName);
    _stage = TextEditingController(text: d.stage);
    _grade = TextEditingController(text: d.grade);
    _year = TextEditingController(text: d.academicYear);
    _driverName = TextEditingController(text: d.driverName);
    _driverPhone = TextEditingController(text: d.driverPhone);
    _driverNationalId = TextEditingController(text: d.driverNationalId);
    _parentName = TextEditingController(text: d.parentName);
    _relationship = TextEditingController(text: d.relationship);
    _parentPhone = TextEditingController(text: d.parentPhone);
  }

  @override
  void dispose() {
    _studentName.dispose();
    _stage.dispose();
    _grade.dispose();
    _year.dispose();
    _driverName.dispose();
    _driverPhone.dispose();
    _driverNationalId.dispose();
    _parentName.dispose();
    _relationship.dispose();
    _parentPhone.dispose();
    super.dispose();
  }

  Future<Uint8List> _buildPdf() async {
    final font = await PdfGoogleFonts.notoNaskhArabicRegular();
    final fontBold = await PdfGoogleFonts.notoNaskhArabicBold();

    String fill(String value) => value.trim().isEmpty ? '........................' : value.trim();

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) {
          pw.Widget line(String label, String value) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 0.6)),
                        ),
                        child: pw.Text(fill(value), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              );

          pw.Widget para(String text) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  text,
                  textAlign: pw.TextAlign.justify,
                  style: const pw.TextStyle(fontSize: 11.5, height: 1.55),
                ),
              );

          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'مدرسة الصقر للغات',
                    style: pw.TextStyle(font: fontBold, fontSize: 16),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'إقرار استلام الطالب بواسطة سائق خاص',
                    style: pw.TextStyle(font: fontBold, fontSize: 15, decoration: pw.TextDecoration.underline),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('العام الدراسي: ${fill(_year.text)}', style: const pw.TextStyle(fontSize: 12)),
                ),
                pw.SizedBox(height: 16),
                line('أقر أنا ولي أمر الطالب/الطالبة:', _parentName.text),
                line('اسم الطالب/الطالبة:', _studentName.text),
                line('المرحلة الدراسية:', _stage.text),
                line('الصف:', _grade.text),
                pw.SizedBox(height: 8),
                para(
                  'بأن نجلي/ابنتي سيغادر المدرسة يومياً مع السائق الموضحة بياناته أدناه، وذلك بناءً على رغبتي الشخصية، وليس باستخدام باص المدرسة.',
                ),
                pw.SizedBox(height: 6),
                pw.Text('بيانات السائق', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                pw.SizedBox(height: 8),
                line('اسم السائق:', _driverName.text),
                line('رقم الهاتف:', _driverPhone.text),
                line('رقم البطاقة القومية:', _driverNationalId.text),
                pw.SizedBox(height: 8),
                para(
                  'وأقر بأنني قد سلمت إدارة المدرسة صورة واضحة من بطاقة الرقم القومي الخاصة بالسائق المذكور.',
                ),
                para(
                  'كما أتعهد بإخطار إدارة المدرسة فوراً في حالة تغيير السائق، مع تقديم بيانات وصورة بطاقة السائق الجديد قبل السماح له باستلام الطالب.',
                ),
                para(
                  'وأتحمل كامل المسؤولية القانونية عن استلام نجلي/ابنتي بواسطة السائق المذكور، وتخلي المدرسة مسؤوليتها بعد تسليم الطالب للسائق المسجل بياناته لدى الإدارة، وذلك وفقاً لهذا الإقرار.',
                ),
                pw.SizedBox(height: 10),
                pw.Text('بيانات ولي الأمر', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                pw.SizedBox(height: 8),
                line('الاسم:', _parentName.text),
                line('صلة القرابة:', _relationship.text),
                line('رقم الهاتف:', _parentPhone.text),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التوقيع: ....................', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('التاريخ: .... / .... / ........', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'iqrar_private_driver_${widget.initial.studentId}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر مشاركة PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إقرار السائق الخاص'),
        actions: [
          IconButton(
            tooltip: 'تصدير PDF',
            onPressed: _exporting ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'مشاركة',
            onPressed: _exporting ? null : _sharePdf,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            gradient: const LinearGradient(colors: AppColors.gradientPrimary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إقرار استلام الطالب بواسطة سائق خاص',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'املأ البيانات ثم صدّر الإقرار PDF بنفس صيغة الورقة الرسمية.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('بيانات الطالب', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextFormField(controller: _year, decoration: const InputDecoration(labelText: 'العام الدراسي')),
          TextFormField(controller: _studentName, decoration: const InputDecoration(labelText: 'اسم الطالب/الطالبة')),
          TextFormField(controller: _stage, decoration: const InputDecoration(labelText: 'المرحلة الدراسية')),
          TextFormField(controller: _grade, decoration: const InputDecoration(labelText: 'الصف')),
          const SizedBox(height: 16),
          const Text('بيانات السائق', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextFormField(controller: _driverName, decoration: const InputDecoration(labelText: 'اسم السائق')),
          TextFormField(controller: _driverPhone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          TextFormField(controller: _driverNationalId, decoration: const InputDecoration(labelText: 'رقم البطاقة القومية')),
          const SizedBox(height: 16),
          const Text('بيانات ولي الأمر', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextFormField(controller: _parentName, decoration: const InputDecoration(labelText: 'الاسم')),
          TextFormField(controller: _relationship, decoration: const InputDecoration(labelText: 'صلة القرابة')),
          TextFormField(controller: _parentPhone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          const SizedBox(height: 20),
          AppCard(
            child: Text(
              'يتضمن الإقرار التعهد بتسليم صورة البطاقة، والإخطار عند تغيير السائق، وتحمل المسؤولية القانونية وتخلي المدرسة مسؤوليتها بعد التسليم.',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _exporting ? null : _exportPdf,
            icon: _exporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('تصدير PDF'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _exporting ? null : _sharePdf,
            icon: const Icon(Icons.share_rounded),
            label: const Text('مشاركة PDF'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}
