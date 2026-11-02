import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key, required this.repositorio});

  final RepositorioLocalizacoes repositorio;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  List<Localizacao> _itens = const [];
  TileProvider? _provedor;
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      // O cache é preparado uma única vez; se falhar, o mapa usa a rede direto.
      if (_provedor == null) {
        try {
          _provedor = await CacheMapa.criarProvedor();
        } catch (_) {
          _provedor = null;
        }
      }
      final itens = await widget.repositorio.consultarUltimas(limite: 100);
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _erro = false;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _carregando = false;
      });
    }
  }

  void _atualizar() {
    setState(() => _carregando = true);
    _carregar();
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar as localizações.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _atualizar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhuma localização registrada.'));
    }
    return MapaLocalizacoes(localizacoes: _itens, tileProvider: _provedor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _atualizar,
          ),
        ],
      ),
      body: _corpo(),
    );
  }
}
