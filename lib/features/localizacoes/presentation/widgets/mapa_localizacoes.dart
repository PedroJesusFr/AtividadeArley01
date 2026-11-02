import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

/// Mapa com camada de ruas (OpenStreetMap) e marcadores.
/// A primeira posição da lista é a mais recente e fica em vermelho.
class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    this.tileProvider,
  });

  /// Não pode ser vazia. Ordem: da mais recente para a mais antiga.
  final List<Localizacao> localizacoes;
  final TileProvider? tileProvider;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  static const EdgeInsets _margem = EdgeInsets.all(56);
  static const double _zoomMaximo = 17;

  final MapController _controlador = MapController();

  List<LatLng> get _pontos => widget.localizacoes
      .map((l) => LatLng(l.latitude, l.longitude))
      .toList();

  bool _degenerado(List<LatLng> pontos) =>
      pontos.every((ponto) => ponto == pontos.first);

  @override
  void didUpdateWidget(covariant MapaLocalizacoes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.localizacoes, widget.localizacoes)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _enquadrar() {
    final pontos = _pontos;
    if (pontos.isEmpty) return;
    if (_degenerado(pontos)) {
      _controlador.move(pontos.first, 16);
      return;
    }
    _controlador.fitCamera(
      CameraFit.coordinates(
        coordinates: pontos,
        padding: _margem,
        maxZoom: _zoomMaximo,
      ),
    );
  }

  void _mostrarDetalhes(Localizacao localizacao) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ItemLocalizacao(localizacao: localizacao),
      ),
    );
  }

  Marker _marcador(Localizacao localizacao, {required bool recente}) {
    return Marker(
      point: LatLng(localizacao.latitude, localizacao.longitude),
      width: 40,
      height: 40,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _mostrarDetalhes(localizacao),
        child: Icon(
          Icons.location_on,
          size: recente ? 40 : 32,
          color: recente ? Colors.red : Colors.indigo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pontos = _pontos;
    final lista = widget.localizacoes;

    // Desenha do mais antigo para o mais recente, que fica por cima.
    final marcadores = <Marker>[
      for (var i = lista.length - 1; i >= 0; i--)
        _marcador(lista[i], recente: i == 0),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCenter: pontos.first,
            initialZoom: 16,
            initialCameraFit: (pontos.length > 1 && !_degenerado(pontos))
                ? CameraFit.coordinates(
                    coordinates: pontos,
                    padding: _margem,
                    maxZoom: _zoomMaximo,
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.localizacoes',
              tileProvider: widget.tileProvider,
            ),
            MarkerLayer(markers: marcadores),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('© Colaboradores do OpenStreetMap'),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'enquadrar',
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _enquadrar,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
