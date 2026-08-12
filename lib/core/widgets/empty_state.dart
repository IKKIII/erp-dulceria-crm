import 'package:flutter/material.dart';
import '../theme.dart';

/// Estado vacío reutilizable: ícono grande, mensaje amigable y una acción
/// opcional (ej. "+ Agregar el primero"). Reemplaza los Text() sueltos que
/// se usaban antes en cada pantalla.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? subtitulo;
  final String? accionTexto;
  final VoidCallback? onAccion;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    this.subtitulo,
    this.accionTexto,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kYellow.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 40, color: kBrown.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrown),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kBrown.withValues(alpha: 0.6)),
              ),
            ],
            if (accionTexto != null && onAccion != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAccion,
                icon: const Icon(Icons.add),
                label: Text(accionTexto!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
