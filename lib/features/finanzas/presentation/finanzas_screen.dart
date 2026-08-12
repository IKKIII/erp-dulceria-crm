import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/session.dart';
import '../../../core/widgets/dialog_header.dart';
import '../data/finanzas_repository_impl.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});
  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final _repo = FinanzasRepositoryImpl();
  List<Map<String, dynamic>> _movs = [];
  List<Map<String, dynamic>> _ventasPeriodo = [];
  List<Map<String, dynamic>> _comprasPeriodo = [];
  double _ingresos = 0, _egresos = 0;
  String _periodo = 'semana'; // 'semana' | 'mes'
  bool _loading = true;
  String? _error;
  bool get _esAdmin => AppSession.instance.role == 'admin';

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
      final movs = await _repo.listarMovimientos();
      final ventasP = await _repo.ventasPorPeriodo(_periodo);
      final comprasP = await _repo.comprasPorPeriodo(_periodo);
      double ingresos = 0, egresos = 0;
      for (final m in movs) {
        final monto = (m['monto'] as num).toDouble();
        if (m['tipo'] == 'ingreso') {
          ingresos += monto;
        } else {
          egresos += monto;
        }
      }
      setState(() {
        _movs = movs;
        _ingresos = ingresos;
        _egresos = egresos;
        _ventasPeriodo = ventasP;
        _comprasPeriodo = comprasP;
      });
    } catch (e) {
      setState(() => _error = 'No se pudo cargar finanzas: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cambiarPeriodo(String p) {
    setState(() => _periodo = p);
    _load();
  }

  void _agregarEgreso() {
    showDialog(context: context, builder: (_) => _EgresoDialog(onSaved: _load));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              onPressed: _agregarEgreso,
              backgroundColor: kOrange,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              label: const Text('Registrar egreso', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kRed)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Row(children: [
                        Expanded(child: _ResumenCard(label: 'Ingresos', value: money(_ingresos), color: kGreen)),
                        const SizedBox(width: 8),
                        Expanded(child: _ResumenCard(label: 'Egresos', value: money(_egresos), color: kRed)),
                      ]),
                      const SizedBox(height: 8),
                      _ResumenCard(label: 'Utilidad', value: money(_ingresos - _egresos), color: kBrown),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ventas y compras',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: kBrown, fontWeight: FontWeight.bold)),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'semana', label: Text('Semana')),
                              ButtonSegment(value: 'mes', label: Text('Mes')),
                            ],
                            selected: {_periodo},
                            onSelectionChanged: (s) => _cambiarPeriodo(s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _GraficaComparativa(ventas: _ventasPeriodo, compras: _comprasPeriodo),
                      const SizedBox(height: 20),
                      Text('Movimientos',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: kBrown, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._movs.map((m) {
                        final fecha = (m['fecha'] ?? '').toString();
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              m['tipo'] == 'ingreso' ? Icons.arrow_downward : Icons.arrow_upward,
                              color: m['tipo'] == 'ingreso' ? kGreen : kRed,
                            ),
                            title: Text(m['concepto'] ?? ''),
                            subtitle: Text(fecha.length >= 16 ? fecha.substring(0, 16) : fecha),
                            trailing: Text(
                              money(m['monto']),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: m['tipo'] == 'ingreso' ? kGreen : kRed),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _GraficaComparativa extends StatelessWidget {
  final List<Map<String, dynamic>> ventas;
  final List<Map<String, dynamic>> compras;
  const _GraficaComparativa({required this.ventas, required this.compras});

  @override
  Widget build(BuildContext context) {
    final etiquetas = <String>{
      ...ventas.map((v) => v['etiqueta'] as String),
      ...compras.map((c) => c['etiqueta'] as String),
    }.toList()
      ..sort();

    double valorDe(List<Map<String, dynamic>> lista, String etiqueta) {
      final match = lista.where((e) => e['etiqueta'] == etiqueta);
      return match.isEmpty ? 0 : (match.first['total'] as num).toDouble();
    }

    final maxY = [
      ...ventas.map((v) => (v['total'] as num).toDouble()),
      ...compras.map((c) => (c['total'] as num).toDouble()),
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    if (etiquetas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Sin datos en este período.')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  barGroups: [
                    for (int i = 0; i < etiquetas.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(toY: valorDe(ventas, etiquetas[i]), color: kGreen, width: 8),
                        BarChartRodData(toY: valorDe(compras, etiquetas[i]), color: kRed, width: 8),
                      ]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= etiquetas.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(etiquetas[i], style: const TextStyle(fontSize: 10, color: kBrown)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _leyenda('Ventas', kGreen),
              const SizedBox(width: 16),
              _leyenda('Compras', kRed),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _leyenda(String texto, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, color: color),
      const SizedBox(width: 4),
      Text(texto, style: const TextStyle(fontSize: 12, color: kBrown)),
    ]);
  }
}

class _ResumenCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResumenCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: kBrown.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}

class _EgresoDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _EgresoDialog({required this.onSaved});
  @override
  State<_EgresoDialog> createState() => _EgresoDialogState();
}

class _EgresoDialogState extends State<_EgresoDialog> {
  final _repo = FinanzasRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _concepto = TextEditingController();
  final _monto = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.registrarEgreso(concepto: _concepto.text.trim(), monto: double.tryParse(_monto.text) ?? 0);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogHeader(icon: Icons.remove_circle_outline, text: 'Registrar egreso', color: kRed),
      content: SizedBox(
        width: dialogWidth(context),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _concepto,
                decoration: const InputDecoration(labelText: 'Concepto'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _monto,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: kRed))),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _guardar,
          child: _loading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
