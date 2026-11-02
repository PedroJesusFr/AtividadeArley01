import 'package:flutter/material.dart';

import 'features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'features/localizacoes/presentation/screens/tela_coleta.dart';
import 'features/localizacoes/services/servico_localizacao.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: TelaColeta(
        repositorio: RepositorioLocalizacoes(),
        servico: ServicoLocalizacao(),
      ),
    );
  }
}
