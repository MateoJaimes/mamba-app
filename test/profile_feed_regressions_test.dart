import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/core/services/account_service.dart';
import 'package:mapo_app/core/theme/app_theme.dart';
import 'package:mapo_app/features/feed/presentation/pages/feed_page.dart';
import 'package:mapo_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mapo_app/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:mapo_app/features/hosts/presentation/pages/host_owner_profile.dart';
import 'package:mapo_app/features/feed/presentation/widgets/experience_image_carousel.dart';

const tourist = AccountSnapshot(
  {
    'display_name': 'Valentina Ríos',
    'handle': 'valen',
    'city': 'Medellín',
    'bio': 'Viajar y descubrir.',
  },
  {'tourist'},
  null,
  null,
);
const host =
    AccountSnapshot({'display_name': 'Nombre privado'}, {'host'}, null, {
      'id': 'mine',
      'display_name': 'MAPO Experiencias',
      'handle': 'somosmamba',
      'city': 'Medellín',
      'bio': 'Historias, café y montañas para compartir.',
      'approved_at': 'today',
    });

void main() {
  testWidgets('carousel paints a delayed image without any scroll or tap', (
    tester,
  ) async {
    final complete = Completer<ImageInfo>(), key = GlobalKey();
    final provider = _DelayedImage(complete.future);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: RepaintBoundary(
              key: key,
              child: ExperienceImageCarousel(
                images: const ['fixture'],
                imageProviderBuilder: (_) => provider,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNull);
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 4, 4),
        Paint()..color = const Color(0xFF59CFC4),
      );
      final picture = recorder.endRecording();
      complete.complete(ImageInfo(image: await picture.toImage(4, 4)));
      picture.dispose();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final i = ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
      expect(bytes!.buffer.asUint8List().sublist(i, i + 3), [52, 211, 153]);
      image.dispose();
    });
  });
  testWidgets('tourist avatar camera receives taps without scrolling', (
    tester,
  ) async {
    int picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfilePage(
          loader: () async => tourist,
          pickPhoto: () async {
            picks++;
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cambiar foto de perfil'));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'host avatar is editable and profile does not duplicate plan management',
    (tester) async {
      int picks = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: HostOwnerProfile(
            account: host,
            onChanged: () {},
            pickPhoto: () async {
              picks++;
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cambiar foto de perfil'));
      await tester.pumpAndSettle();
      expect(picks, 1);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Crear plan'), findsNothing);
      expect(find.text('Editar plan'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('settings contains options without identity header', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileSettingsPage(loader: () async => host)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nombre privado'), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('Información personal'), findsOneWidget);
    expect(find.text('País y ciudad'), findsOneWidget);
    expect(find.text('Mi espacio de anfitrión'), findsNothing);
  });
  testWidgets('feed paints delayed initial data without a scroll gesture', (
    tester,
  ) async {
    final result = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(
      MaterialApp(
        home: FeedPage(
          loader: (_, _, _) => result.future,
          cardBuilder: (_, plan) =>
              SizedBox(height: 220, child: Text('${plan['title']}')),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    result.complete([
      {
        'id': 'one',
        'title': 'Plan cargado al abrir',
        'images': <String>[],
        'categories': ['Cultura'],
      },
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Plan cargado al abrir'), findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
    expect(tester.takeException(), isNull);
  });
}

class _DelayedImage extends ImageProvider<_DelayedImage> {
  const _DelayedImage(this.future);
  final Future<ImageInfo> future;
  @override
  Future<_DelayedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    _DelayedImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(future);
}
