/// Registro de uma posição coletada.
class Localizacao {
  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  final int? id;
  final double latitude;
  final double longitude;

  /// Precisão estimada, em metros.
  final double precisao;

  /// Instante da leitura (sempre guardado em UTC).
  final DateTime instante;

  factory Localizacao.deMapa(Map<String, Object?> mapa) {
    return Localizacao(
      id: mapa['id'] as int?,
      latitude: (mapa['latitude'] as num).toDouble(),
      longitude: (mapa['longitude'] as num).toDouble(),
      precisao: (mapa['precisao'] as num).toDouble(),
      instante: DateTime.parse(mapa['instante'] as String).toUtc(),
    );
  }

  Map<String, Object?> paraMapa() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': instante.toUtc().toIso8601String(),
    };
  }

  Localizacao comId(int novoId) {
    return Localizacao(
      id: novoId,
      latitude: latitude,
      longitude: longitude,
      precisao: precisao,
      instante: instante,
    );
  }
}
