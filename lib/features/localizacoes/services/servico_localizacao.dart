import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

enum ResultadoAcesso {
  concedido,
  servicoDesabilitado,
  negado,
  negadoPermanentemente,
}

/// Verifica GPS e permissões e fornece o stream de posições.
class ServicoLocalizacao {
  static const Duration intervalo = Duration(seconds: 20);

  Future<ResultadoAcesso> garantirAcesso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return ResultadoAcesso.servicoDesabilitado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    switch (permissao) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return ResultadoAcesso.negado;
      case LocationPermission.deniedForever:
        return ResultadoAcesso.negadoPermanentemente;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return ResultadoAcesso.concedido;
    }
  }

  /// Android 13+: necessária para a notificação do serviço em primeiro plano
  /// ficar visível. A coleta não depende da resposta.
  Future<void> solicitarPermissaoNotificacao() async {
    if (!Platform.isAndroid) return;
    final status = await ph.Permission.notification.status;
    if (status.isDenied) {
      await ph.Permission.notification.request();
    }
  }

  Stream<Position> posicoes() {
    final LocationSettings configuracao;
    if (Platform.isAndroid) {
      configuracao = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: intervalo,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localização ativa',
          notificationText: 'O aplicativo está registrando sua posição.',
          notificationChannelName: 'Coleta de localização',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (Platform.isIOS) {
      configuracao = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      configuracao = const LocationSettings(accuracy: LocationAccuracy.high);
    }
    return Geolocator.getPositionStream(locationSettings: configuracao);
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();
}
