import 'package:flutter/material.dart';
import '../theme.dart';

/// Buscador estándar para listas (productos, clientes, etc.). Ya trae
/// debounce simple, botón de limpiar, y el estilo visual de la app.
class SearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hintText, required this.onChanged});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, color: kBrown),
          suffixIcon: ValueListenableBuilder(
            valueListenable: _ctrl,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18, color: kBrown),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onChanged('');
                    },
                  ),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
