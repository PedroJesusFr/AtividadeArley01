import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre o banco uma única vez e reutiliza a conexão.
/// Se a abertura falhar, a próxima chamada tenta novamente.
class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const String nomeArquivo = 'localizacoes.db';
  static const int versao = 1;
  static const String tabela = 'localizacoes';

  Future<Database>? _abertura;

  Future<Database> get banco async {
    final pendente = _abertura ??= _abrir();
    try {
      return await pendente;
    } catch (_) {
      _abertura = null; // permite nova tentativa
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final caminho = p.join(await getDatabasesPath(), nomeArquivo);
    return openDatabase(
      caminho,
      version: versao,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $tabela (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
