import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

/// Único ponto de acesso ao SQLite para as telas.
class RepositorioLocalizacoes {
  RepositorioLocalizacoes({BancoLocalizacoes? banco})
      : _banco = banco ?? BancoLocalizacoes.instancia;

  final BancoLocalizacoes _banco;

  Future<Localizacao> inserir(Localizacao localizacao) async {
    final db = await _banco.banco;
    final id = await db.insert(
      BancoLocalizacoes.tabela,
      localizacao.paraMapa(),
    );
    return localizacao.comId(id);
  }

  /// Retorna as últimas [limite] posições, da mais recente para a mais antiga.
  /// O limite vale só para a consulta; nada é apagado.
  Future<List<Localizacao>> consultarUltimas({int limite = 100}) async {
    final db = await _banco.banco;
    final linhas = await db.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.deMapa).toList();
  }

  /// Remove todas as linhas, preservando tabela e arquivo do banco.
  Future<void> excluirTodas() async {
    final db = await _banco.banco;
    await db.delete(BancoLocalizacoes.tabela);
  }
}
