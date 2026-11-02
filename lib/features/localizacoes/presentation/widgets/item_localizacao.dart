import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({super.key, required this.localizacao});

  final Localizacao localizacao;

  static final DateFormat _formato = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final l = localizacao;
    return ListTile(
      leading: const Icon(Icons.place),
      title: Text(_formato.format(l.instante.toLocal())),
      subtitle: Text(
        'Lat: ${l.latitude.toStringAsFixed(6)}\n'
        'Lon: ${l.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${l.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
