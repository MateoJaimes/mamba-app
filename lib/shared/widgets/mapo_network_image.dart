import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/env.dart';

Uri? _privateMediaUri(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return null;
  const prefix = '/storage/v1/object/authenticated/user-media/';
  if (!uri.host.endsWith('.supabase.co') || !uri.path.startsWith(prefix)) {
    return null;
  }
  final objectPath = uri.path.substring(prefix.length);
  if (!RegExp(r'^[a-f0-9-]{36}/[a-f0-9-]{36}\.webp$').hasMatch(objectPath)) {
    return null;
  }
  final api = Uri.tryParse(AppEnvironment.supabaseUrl);
  return api?.resolve('/api/media/$objectPath');
}

ImageProvider mapoImageProvider(String url) {
  final privateUri = _privateMediaUri(url);
  if (privateUri == null) return CachedNetworkImageProvider(url);
  final session = AppEnvironment.hasSupabaseConfig
      ? Supabase.instance.client.auth.currentSession
      : null;
  return NetworkImage(
    privateUri
        .replace(
          // Partition Flutter's in-memory cache by signed-in account.
          queryParameters: {'viewer': session?.user.id ?? 'guest'},
        )
        .toString(),
    headers: session == null
        ? null
        : {'Authorization': 'Bearer ${session.accessToken}'},
  );
}

class MapoNetworkImage extends StatelessWidget {
  const MapoNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.memCacheWidth,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (_privateMediaUri(imageUrl) == null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
    return Image(
      image: ResizeImage.resizeIfNeeded(
        memCacheWidth,
        null,
        mapoImageProvider(imageUrl),
      ),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, _) =>
          errorWidget?.call(context, imageUrl, error) ??
          const SizedBox.shrink(),
      frameBuilder: placeholder == null
          ? null
          : (context, child, frame, _) =>
                frame == null ? placeholder!(context, imageUrl) : child,
    );
  }
}
