import 'dart:io';

import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Prepara o cache de imagens do mapa em pasta privada do aplicativo.
class CacheMapa {
  static const Duration validade = Duration(days: 7);

  static Future<TileProvider> criarProvedor() async {
    final base = await getApplicationCacheDirectory();
    final pasta = Directory(p.join(base.path, 'tiles_mapa'));
    await pasta.create(recursive: true);
    return CachedTileProvider(
      maxStale: validade,
      store: FileCacheStore(pasta.path),
    );
  }
}
