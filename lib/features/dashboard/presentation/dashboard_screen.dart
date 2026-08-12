import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../data/dashboard_repository_impl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepositoryImpl();
  Map<String, dynamic>? _data;
  bool _loading = true;
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
      final data = await _repo.obtenerKpis();
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar el dashboard: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: _load);

    final d = _data!;
    final stockBajo = (d['stock_bajo'] as List? ?? []);
    final topProductos = (d['top_productos'] as List? ?? []);
    final ventasPorDia = (d['ventas_por_dia'] as List? ?? []);
    final maxVenta = ventasPorDia.fold<double>(
        1, (acc, v) => (v['total'] as num).toDouble() > acc ? (v['total'] as num).toDouble() : acc);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _KpiCard(label: 'Ventas totales', value: money(d['ventas_total'])),
              _KpiCard(label: 'Utilidad estimada', value: money(d['utilidad'])),
              _KpiCard(label: 'Valor de inventario', value: money(d['inventario_valor'])),
              _KpiCard(label: 'Alertas de stock bajo', value: '${stockBajo.length}'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Ventas — Últimos 7 días',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kBrown, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: BarChart(
                  BarChartData(
                    maxY: maxVenta * 1.2,
                    barGroups: [
                      for (int i = 0; i < ventasPorDia.length; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: (ventasPorDia[i]['total'] as num).toDouble(),
                            color: kOrange,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
                            if (i < 0 || i >= ventasPorDia.length) return const SizedBox.shrink();
                            final dia = (ventasPorDia[i]['dia'] as String);
                            final corto = dia.length >= 10 ? dia.substring(5) : dia;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(corto, style: const TextStyle(fontSize: 10, color: kBrown)),
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
            ),
          ),
          const SizedBox(height: 20),
          Text('Top productos más vendidos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kBrown, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (topProductos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aún no hay ventas registradas.'),
            ),
          ...topProductos.map((p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined, color: kOrange),
                  title: Text(p['nombre'] ?? ''),
                  trailing: Text('${p['cantidad_vendida']} uds',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                ),
              )),
          const SizedBox(height: 10),
          if (stockBajo.isNotEmpty) ...[
            Text('Alertas de stock bajo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kRed, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...stockBajo.map((p) => Card(
                  color: const Color(0xFFFFF1F0),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: kRed),
                    title: Text(p['nombre'] ?? ''),
                    trailing: Text('${p['stock']} / mín ${p['stock_minimo']}',
                        style: const TextStyle(color: kRed, fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  const _KpiCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: kBrown.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: kRed, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kRed)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      ),
    );
  }
}
