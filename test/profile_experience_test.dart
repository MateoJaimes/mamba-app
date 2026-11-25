import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/core/services/account_service.dart';
import 'package:mapo_app/core/services/currency_service.dart';
import 'package:mapo_app/core/theme/app_theme.dart';
import 'package:mapo_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mapo_app/features/experiences/presentation/pages/experience_detail_page.dart';
import 'package:mapo_app/features/hosts/data/demo_host_catalog.dart';

void main() {
  test('foreign currency display never mutates the canonical plan price', () {
    final service = CurrencyService.instance;
    final plan = <String, dynamic>{'price_amount': 60000};
    service.code = 'USD';
    service.rate = 0.000291;
    expect(service.format(CurrencyService.amount(plan)), contains('17,46'));
    expect(service.format(60000), startsWith('≈'));
    expect(plan['price_amount'], 60000);
    service.code = 'COP';
    service.rate = 1;
    expect(service.format(60000), contains('60.000'));
    expect(service.format(60000), isNot(contains('≈')));
  });
  testWidgets(
    'tourist overview shows personal information and settings without menu clutter',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final font = FontLoader('Roboto');
      await tester.runAsync(() async {
        font.addFont(
          Future.value(
            ByteData.sublistView(
              await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes(),
            ),
          ),
        );
        await font.load();
        final icons = FontLoader("MaterialIcons");
        icons.addFont(rootBundle.load("fonts/MaterialIcons-Regular.otf"));
        await icons.load();
      });
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RepaintBoundary(
            key: key,
            child: ProfilePage(
              loader: () async => const AccountSnapshot(
                {
                  'display_name': 'Valentina Ríos',
                  'handle': 'valen.explora',
                  'city': 'Medellín',
                  'country': 'Colombia',
                  'bio': 'Me pierdo entre montañas, cafés y buenas historias.',
                  'interests': ['Naturaleza', 'Gastronomía', 'Cultura'],
                },
                {'tourist'},
                null,
                null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Valentina Ríos'), findsOneWidget);
      expect(find.byTooltip('Configuración'), findsOneWidget);
      expect(find.text('Lo que me mueve'), findsOneWidget);
      expect(find.text('Mis inscripciones'), findsNothing);
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/design-preview').create(recursive: true);
        await File(
          'build/design-preview/tourist-profile.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    },
  );
  testWidgets(
    'detail photos remain swipeable through the decorative gradient',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ExperienceDetailPage(
            experienceId: '${DemoHostCatalog.experiences.first['id']}',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final gallery = find.byType(PageView);
      expect(gallery, findsOneWidget);
      await tester.drag(gallery, const Offset(-320, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      final scrollable = find
          .descendant(of: gallery, matching: find.byType(Scrollable))
          .first;
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(300),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
