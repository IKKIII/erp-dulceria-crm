import 'package:flutter/material.dart';
import '../theme.dart';

/// Header con ícono + título para usarlo como `title:` de un AlertDialog.
/// Reemplaza los títulos de solo texto para dar más presencia visual
/// (círculo de color detrás del ícono, a juego con la paleta de marca).
class DialogHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const DialogHeader({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kBrown;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, color: c, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kBrown),
          ),
        ),
      ],
    );
  }
}
