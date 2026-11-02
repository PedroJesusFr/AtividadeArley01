# Atividade 1 – Coleta e visualização de localizações

Integrantes: Pedro Enrique

## Como montar o projeto
1. Crie o projeto base (o nome e a organização definem o applicationId `com.example.localizacoes`,
   usado também no `userAgentPackageName` do mapa):
   `flutter create --org com.example --project-name localizacoes --platforms android,ios .`
2. Copie por cima do projeto criado: `lib/`, `assets/`, `pubspec.yaml` e o conteúdo de
   `android/app/src/main/` (AndroidManifest.xml e res/).
3. `flutter pub get`, depois `dart format .` e `flutter analyze`.
4. Rode em aparelho real: `flutter run`.

## Notas
- Coleta: `Geolocator.getPositionStream` com alta precisão, intervalo de 20 s e serviço em primeiro plano (Android).
- Mapa: OpenStreetMap com cache em pasta privada; atribuição exibida no mapa.
- No Android, compileSdk 34+ e minSdk 21+ (padrão do Flutter atual).
- iOS: adicione em `Info.plist` as chaves `NSLocationWhenInUseUsageDescription` e
  `NSLocationAlwaysAndWhenInUseUsageDescription`, e habilite *Background Modes → Location updates*.
- Não adicione `localizacoes.db` ao repositório.
