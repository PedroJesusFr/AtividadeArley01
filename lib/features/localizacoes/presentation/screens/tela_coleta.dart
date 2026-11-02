import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({
    super.key,
    required this.repositorio,
    required this.servico,
  });

  final RepositorioLocalizacoes repositorio;
  final ServicoLocalizacao servico;

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  StreamSubscription<Position>? _assinatura;
  final ValueNotifier<bool> _coletaAtiva = ValueNotifier<bool>(false);

  bool _iniciando = false;
  int _gravadas = 0;
  Localizacao? _ultima;
  String? _erroGravacao;

  /// Fila que serializa as gravações para que nunca se sobreponham.
  Future<void> _filaGravacao = Future<void>.value();

  @override
  void dispose() {
    _assinatura?.cancel();
    _assinatura = null;
    _coletaAtiva.dispose();
    super.dispose();
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _dialogoConfiguracao({
    required String titulo,
    required String texto,
    required String rotuloAcao,
    required Future<bool> Function() acao,
  }) async {
    if (!mounted) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(rotuloAcao),
          ),
        ],
      ),
    );
    if (confirmou == true) await acao();
  }

  Future<void> _orientar(ResultadoAcesso resultado) async {
    switch (resultado) {
      case ResultadoAcesso.concedido:
        return;
      case ResultadoAcesso.servicoDesabilitado:
        await _dialogoConfiguracao(
          titulo: 'Localização desativada',
          texto: 'Ative o GPS do aparelho para iniciar a coleta.',
          rotuloAcao: 'Abrir configurações',
          acao: widget.servico.abrirConfiguracoesLocalizacao,
        );
      case ResultadoAcesso.negado:
        _mensagem('Permissão de localização negada. A coleta não foi iniciada.');
      case ResultadoAcesso.negadoPermanentemente:
        await _dialogoConfiguracao(
          titulo: 'Permissão necessária',
          texto: 'A permissão de localização foi negada permanentemente. '
              'Habilite-a nas configurações do aplicativo.',
          rotuloAcao: 'Abrir configurações',
          acao: widget.servico.abrirConfiguracoesApp,
        );
    }
  }

  void _definirAtiva(bool valor) {
    _coletaAtiva.value = valor;
    if (mounted) setState(() {});
  }

  Future<void> _iniciar() async {
    if (_assinatura != null || _iniciando) return;
    setState(() => _iniciando = true);
    try {
      final acesso = await widget.servico.garantirAcesso();
      if (!mounted) return;
      if (acesso != ResultadoAcesso.concedido) {
        await _orientar(acesso);
        return;
      }

      await widget.servico.solicitarPermissaoNotificacao();
      if (!mounted || _assinatura != null) return;

      _assinatura = widget.servico.posicoes().listen(
            _aoReceberPosicao,
            onError: _aoOcorrerErro,
          );
      _definirAtiva(true);
    } catch (_) {
      _mensagem('Não foi possível iniciar a coleta.');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _parar() async {
    final assinatura = _assinatura;
    _assinatura = null;
    await assinatura?.cancel();
    _definirAtiva(false);
  }

  void _aoReceberPosicao(Position posicao) {
    _filaGravacao = _filaGravacao.then((_) => _gravar(posicao));
  }

  Future<void> _aoOcorrerErro(Object erro) async {
    await _parar();
    if (erro is PermissionDeniedException) {
      _mensagem('Permissão de localização perdida. Coleta interrompida.');
    } else if (erro is LocationServiceDisabledException) {
      _mensagem('GPS desativado. Coleta interrompida.');
    } else {
      _mensagem('Erro na coleta de localização. Coleta interrompida.');
    }
  }

  Future<void> _gravar(Position posicao) async {
    final nova = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );
    try {
      final salva = await widget.repositorio.inserir(nova);
      if (!mounted) return;
      setState(() {
        _ultima = salva;
        _gravadas++;
        _erroGravacao = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erroGravacao = 'Falha ao gravar a última posição.');
    }
  }

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  Future<void> _abrirConfiguracoesPermissao() async {
    final abriu = await widget.servico.abrirConfiguracoesApp();
    if (!abriu) _mensagem('Não foi possível abrir as configurações.');
  }

  @override
  Widget build(BuildContext context) {
    final ativa = _coletaAtiva.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localização')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          ativa ? Icons.radio_button_checked : Icons.pause_circle,
                          color: ativa ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ativa ? 'Coleta ativa' : 'Coleta parada',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Posições gravadas nesta sessão: $_gravadas'),
                    if (_erroGravacao != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _erroGravacao!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_ultima != null) ...[
              const SizedBox(height: 8),
              Card(child: ItemLocalizacao(localizacao: _ultima!)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (ativa || _iniciando) ? null : _iniciar,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: ativa ? _parar : null,
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _abrir(
                TelaLocalizacoes(
                  repositorio: widget.repositorio,
                  coletaAtiva: _coletaAtiva,
                ),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _abrir(TelaMapa(repositorio: widget.repositorio)),
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _abrirConfiguracoesPermissao,
              icon: const Icon(Icons.settings),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    );
  }
}
