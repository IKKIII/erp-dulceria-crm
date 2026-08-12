import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../data/reportes_repository_impl.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _repo = ReportesRepositoryImpl();
  Map<String, dynamic>? _kpis;
  List<Map<String, dynamic>> _compras = [];
  List<Map<String, dynamic>> _ventas = [];
  List<Map<String, dynamic>> _finanzas = [];
  bool _loading = true;
  bool _generandoPdf = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final kpis = await _repo.obtenerKpis();
      final compras = await _repo.comprasRecientes();
      final ventas = await _repo.ventasRecientes();
      final finanzas = await _repo.movimientosFinancieros();
      setState(() {
        _kpis = kpis;
        _compras = compras;
        _ventas = ventas;
        _finanzas = finanzas;
      });
    } catch (e) {
      setState(() => _error = 'No se pudo cargar reportes: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _fecha(dynamic v) {
    final s = (v ?? '').toString();
    return s.length >= 16 ? s.substring(0, 16) : s;
  }

  Future<void> _generarPdf() async {
    if (_kpis == null) return;
    setState(() => _generandoPdf = true);
    try {
      final d = _kpis!;
      final empresa = AppSession.instance.empresa ?? 'ERP Dulcería';
      final ahora = DateTime.now();
      String fechaStr;
      try {
        fechaStr = DateFormat("d 'de' MMMM 'de' y", 'es_MX').format(ahora);
      } catch (_) {
        fechaStr = '${ahora.day}/${ahora.month}/${ahora.year}';
      }

      const brown = PdfColor.fromInt(0xFF8B6F47);
      const orange = PdfColor.fromInt(0xFFFFB347);
      const cream = PdfColor.fromInt(0xFFFFF8E5);
      const yellow = PdfColor.fromInt(0xFFFFD966);
      const muted = PdfColor.fromInt(0xFFA0826D);

      final topProductos = (d['top_productos'] as List? ?? []);
      final stockBajo = (d['stock_bajo'] as List? ?? []);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: yellow, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Row(children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                    color: PdfColors.white, shape: pw.BoxShape.circle, border: pw.Border.all(color: orange, width: 2)),
                alignment: pw.Alignment.center,
                child: pw.Text('D', style: const pw.TextStyle(color: brown, fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.SizedBox(width: 12),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(empresa, style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brown)),
                pw.Text('Reporte general del negocio', style: const pw.TextStyle(fontSize: 10, color: brown)),
                pw.Text('Generado el $fechaStr', style: const pw.TextStyle(fontSize: 8, color: muted)),
              ]),
            ]),
          ),
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: yellow, width: 0.5))),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('$empresa — ERP Dulcería', style: const pw.TextStyle(fontSize: 8, color: muted)),
              pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: muted)),
            ]),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.Row(children: [
              _kpiBox('Ventas totales', money(d['ventas_total']), brown, yellow),
              pw.SizedBox(width: 6),
              _kpiBox('Utilidad estimada', money(d['utilidad']), brown, yellow),
              pw.SizedBox(width: 6),
              _kpiBox('Valor de inventario', money(d['inventario_valor']), brown, yellow),
              pw.SizedBox(width: 6),
              _kpiBox('Stock bajo', '${stockBajo.length}', brown, yellow),
            ]),
            pw.SizedBox(height: 16),
            _seccionTitulo('Top productos más vendidos', orange, brown),
            if (topProductos.isEmpty)
              pw.Text('Aún no hay ventas registradas.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, color: muted))
            else
              pw.Table.fromTextArray(
                headers: const ['Producto', 'Unidades vendidas'],
                data: topProductos.map((p) => [p['nombre'].toString(), p['cantidad_vendida'].toString()]).toList(),
                headerDecoration: const pw.BoxDecoration(color: orange),
                headerStyle: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9, color: brown),
                oddRowDecoration: const pw.BoxDecoration(color: cream),
              ),
            pw.SizedBox(height: 16),
            _seccionTitulo('Compras recientes', orange, brown),
            if (_compras.isEmpty)
              pw.Text('Sin compras registradas.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, color: muted))
            else
              pw.Table.fromTextArray(
                headers: const ['#', 'Proveedor', 'Fecha', 'Total'],
                data: _compras
                    .map((c) => [
                          '${c['id']}',
                          (c['proveedores'] is Map) ? c['proveedores']['nombre'].toString() : '—',
                          _fecha(c['fecha']),
                          money(c['total']),
                        ])
                    .toList(),
                headerDecoration: const pw.BoxDecoration(color: orange),
                headerStyle: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9, color: brown),
                oddRowDecoration: const pw.BoxDecoration(color: cream),
              ),
            pw.SizedBox(height: 16),
            _seccionTitulo('Ventas recientes', orange, brown),
            if (_ventas.isEmpty)
              pw.Text('Sin ventas registradas.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, color: muted))
            else
              pw.Table.fromTextArray(
                headers: const ['#', 'Cliente', 'Fecha', 'Total'],
                data: _ventas
                    .map((v) => [
                          '${v['id']}',
                          (v['clientes'] is Map) ? v['clientes']['nombre'].toString() : 'Público General',
                          _fecha(v['fecha']),
                          money(v['total']),
                        ])
                    .toList(),
                headerDecoration: const pw.BoxDecoration(color: orange),
                headerStyle: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9, color: brown),
                oddRowDecoration: const pw.BoxDecoration(color: cream),
              ),
            pw.SizedBox(height: 16),
            _seccionTitulo('Movimientos financieros', orange, brown),
            if (_finanzas.isEmpty)
              pw.Text('Sin movimientos financieros.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, color: muted))
            else
              pw.Table.fromTextArray(
                headers: const ['Tipo', 'Concepto', 'Monto', 'Fecha'],
                data: _finanzas
                    .map((m) => [
                          m['tipo'] == 'ingreso' ? 'Ingreso' : 'Egreso',
                          m['concepto'].toString(),
                          money(m['monto']),
                          _fecha(m['fecha']),
                        ])
                    .toList(),
                headerDecoration: const pw.BoxDecoration(color: orange),
                headerStyle: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9, color: brown),
                oddRowDecoration: const pw.BoxDecoration(color: cream),
              ),
          ],
        ),
      );

      final bytes = await doc.save();
      final nombreArchivo =
          'Reporte_${empresa.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_${ahora.toIso8601String().substring(0, 10)}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo generar el PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  static pw.Widget _kpiBox(String label, String value, PdfColor brown, PdfColor yellow) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: yellow), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brown)),
          pw.SizedBox(height: 3),
          pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFA0826D))),
        ]),
      ),
    );
  }

  static pw.Widget _seccionTitulo(String txt, PdfColor orange, PdfColor brown) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(children: [
        pw.Container(width: 3, height: 12, color: orange),
        pw.SizedBox(width: 6),
        pw.Text(txt, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brown)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kRed)));
    final d = _kpis!;
    final stockBajo = (d['stock_bajo'] as List? ?? []);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generandoPdf ? null : _generarPdf,
                icon: _generandoPdf
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_generandoPdf ? 'Generando…' : 'Descargar / compartir PDF'),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _KpiTile(label: 'Ventas totales', value: money(d['ventas_total'])),
                _KpiTile(label: 'Utilidad estimada', value: money(d['utilidad'])),
                _KpiTile(label: 'Valor de inventario', value: money(d['inventario_valor'])),
                _KpiTile(label: 'Alertas de stock bajo', value: '${stockBajo.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label, value;
  const _KpiTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: kBrown.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}
