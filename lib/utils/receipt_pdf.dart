// lib/utils/receipt_pdf.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate();
  return null;
}

String _fmtMoney(num? n) {
  final v = (n ?? 0).toInt();
  final f = NumberFormat.decimalPattern('fr_FR');
  return '${f.format(v)} FCFA';
}

String _fmtDateTimeFr(DateTime dt) {
  final f = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  return f.format(dt);
}

/// Construit le PDF du reçu et retourne les bytes.
Future<Uint8List> buildOrderReceiptPdf({
  required String orderId,
  required Map<String, dynamic> data,
}) 
async {
  final createdAt = _toDate(data['createdAt']);
  final pickupAt  = _toDate(data['pickupAt']);
  final items = ((data['items'] as List?) ?? const [])
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();

  final total   = (data['total'] as num?) ?? 0;
  final address = (data['address'] as String?) ?? '';
  final phone   = (data['phone'] as String?) ?? '';
  final userId  = (data['userId'] as String?) ?? '';
  final status  = (data['status'] as String?) ?? 'pending';

  final pdf = pw.Document();

  final titleStyle     = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
  const labelStyle     = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
  const valueStyle     = pw.TextStyle(fontSize: 11);
  final boldValueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        // En-tête
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TOO PRESSING', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Reçu de commande', style: titleStyle),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'order:$orderId',
                  width: 60,
                  height: 60,
                ),
                pw.SizedBox(height: 4),
                pw.Text('#${orderId.substring(0, 6)}', style: labelStyle),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(),

        // Infos
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Informations client', style: titleStyle),
                  pw.SizedBox(height: 6),
                  _infoLine('Téléphone', phone, labelStyle, valueStyle),
                  _infoLine('Adresse', address.isEmpty ? '-' : address, labelStyle, valueStyle),
                  _infoLine('Client UID', userId.isEmpty ? '-' : userId, labelStyle, valueStyle),
                ],
              ),
            ),
            pw.SizedBox(width: 18),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Détails commande', style: titleStyle),
                  pw.SizedBox(height: 6),
                  _infoLine('Statut', status, labelStyle, valueStyle),
                  if (createdAt != null) _infoLine('Créée', _fmtDateTimeFr(createdAt), labelStyle, valueStyle),
                  if (pickupAt  != null) _infoLine('Collecte prévue', _fmtDateTimeFr(pickupAt), labelStyle, valueStyle),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 14),
        pw.Divider(),

        // Articles
        pw.SizedBox(height: 10),
        pw.Text('Articles', style: titleStyle),
        pw.SizedBox(height: 8),

        if (items.isEmpty)
          pw.Text('Aucun article', style: valueStyle)
        else
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              outside: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: [
                  _cellHeader('Article'),
                  _cellHeader('Qté'),
                  _cellHeader('Total'),
                ],
              ),
              ...items.map((it) {
                final name      = (it['name'] as String?) ?? '-';
                final qty       = (it['quantity'] as num?)?.toInt() ?? 0;
                final lineTotal = (it['lineTotal'] as num?) ?? 0;
                return pw.TableRow(
                  children: [
                    _cell(name),
                    _cell('$qty'),
                    _cell(_fmtMoney(lineTotal), alignRight: true),
                  ],
                );
              }),
            ],
          ),

        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Text('Total : ', style: labelStyle.copyWith(fontSize: 12)),
                  pw.Text(_fmtMoney(total), style: boldValueStyle),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 18),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Merci pour votre confiance !',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _infoLine(
  String label,
  String value,
  pw.TextStyle labelStyle,
  pw.TextStyle valueStyle,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '$label : ', style: labelStyle),
          pw.TextSpan(text: value, style: valueStyle),
        ],
      ),
    ),
  );
}

pw.Widget _cellHeader(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
    );

pw.Widget _cell(String text, {bool alignRight = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      ),
    );