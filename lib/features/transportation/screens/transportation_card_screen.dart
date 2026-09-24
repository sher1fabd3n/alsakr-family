import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transportation_models.dart';
import '../services/transportation_service.dart';
import '../widgets/transportation_id_card.dart';
import '../../parent/state/parent_child_context.dart';
import '../../parent/widgets/child_photo_actions.dart';

class TransportationCardScreen extends StatefulWidget {
  const TransportationCardScreen({super.key, this.studentId});

  final int? studentId;

  @override
  State<TransportationCardScreen> createState() => _TransportationCardScreenState();
}

class _TransportationCardScreenState extends State<TransportationCardScreen> {
  final _cardKey = GlobalKey();
  late Future<TransportationCardData> _future;
  int _seenPhotoRevision = -1;

  @override
  void initState() {
    super.initState();
    _future = context.read<TransportationService>().getCard(studentId: widget.studentId);
  }

  Future<Uint8List?> _captureCard() async {
    final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _shareCard(TransportationCardData card) async {
    final bytes = await _captureCard();
    if (bytes == null || !mounted) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/transport_card_${card.studentCode}.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'بطاقة النقل - ${card.studentName}'),
    );
  }

  Future<void> _printCard(TransportationCardData card) async {
    final bytes = await _captureCard();
    if (bytes == null) return;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final photoRevision = context.watch<ParentChildContext>().photoRevision;
    if (_seenPhotoRevision != photoRevision) {
      _seenPhotoRevision = photoRevision;
      if (_seenPhotoRevision > 0) {
        _future = context.read<TransportationService>().getCard(studentId: widget.studentId);
      }
    }
    final studentId = widget.studentId ?? context.watch<ParentChildContext>().activeStudentId;
    return Scaffold(
      appBar: AppBar(title: const Text('بطاقة النقل')),
      body: FutureBuilder<TransportationCardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final card = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: TransportationIdCard(
                  card: card,
                  studentId: studentId,
                  onPhotoTap: studentId == null
                      ? null
                      : () => ChildPhotoActions.pickAndUpload(context, studentId),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _printCard(card),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('طباعة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareCard(card),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
