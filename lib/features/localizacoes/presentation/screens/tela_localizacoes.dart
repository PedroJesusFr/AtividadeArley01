import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({
    super.key,
    required this.repositorio,
    required this.coletaAtiva,
  });

  final RepositorioLocalizacoes repositorio;
  final ValueListenable<bool> coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  List<Localizacao> _itens = const [];
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
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

  void _recarregarComEspera() {
    setState(() => _carregando = true);
    _carregar();
  }

  Future<void> _limpar() async {
    final aviso = StringBuffer(
      'Todos os registros serão apagados, inclusive os anteriores aos 100 '
      'exibidos. Esta operação é permanente.',
    );
    if (widget.coletaAtiva.value) {
      aviso.write(
        '\n\nA coleta está ativa: novos registros continuarão sendo salvos.',
      );
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar histórico'),
        content: Text(aviso.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await widget.repositorio.excluirTodas();
      if (!mounted) return;
      await _carregar();
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Histórico apagado com sucesso.')),
      );
    } catch (_) {
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Falha ao apagar o histórico.')),
      );
    }
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
            const Text('Não foi possível carregar o histórico.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _recarregarComEspera,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhuma localização registrada.'));
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        itemCount: _itens.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ItemLocalizacao(localizacao: _itens[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recarregarComEspera,
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _limpar,
          ),
        ],
      ),
      body: _corpo(),
    );
  }
}
