import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/core/routes/account_destination.dart';
import 'package:mapo_app/core/routes/app_router.dart';
import 'package:mapo_app/features/hosts/presentation/pages/host_dashboard_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mapo_app/core/services/account_service.dart';
import 'package:mapo_app/core/services/account_session.dart';
import 'package:mapo_app/features/hosts/presentation/pages/host_agenda_page.dart';
import 'package:mapo_app/features/hosts/presentation/pages/host_plans_page.dart';

void main() {
  testWidgets(
    'approved host branches replace map, tourist calendar and tourist profile',
    (tester) async {
      final session = AccountSession.instance;
      session.account = const AccountSnapshot(
        {},
        {'host'},
        null,
        {'id': 'mine', 'approved_at': 'today'},
      );
      final router = createAppRouter(
        authConfigured: false,
        authRequired: false,
      );
      addTearDown(() {
        router.dispose();
        session.account = null;
      });
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/map');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HostPlansPage), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      router.go('/calendar');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HostAgendaPage), findsOneWidget);
      router.go('/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<HostDashboardPage>(find.byType(HostDashboardPage))
            .embedded,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'host navigation requires role and approval, not registration intent',
    (tester) async {
      final session = AccountSession.instance;
      addTearDown(() => session.account = null);
      session.account = const AccountSnapshot(
        {'account_intent': 'experience_host'},
        {'tourist'},
        null,
        null,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: AccountDestination(
            tourist: Text('Mapa turista'),
            host: Text('Mis planes'),
          ),
        ),
      );
      expect(find.text('Mapa turista'), findsOneWidget);
      expect(find.text('Mis planes'), findsNothing);
      session.account = const AccountSnapshot(
        {},
        {'host'},
        null,
        {'id': 'mine', 'approved_at': 'today'},
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: AccountDestination(
            key: ValueKey('host'),
            tourist: Text('Mapa turista'),
            host: Text('Mis planes'),
          ),
        ),
      );
      expect(find.text('Mis planes'), findsOneWidget);
      expect(find.text('Mapa turista'), findsNothing);
    },
  );
  test(
    'host agenda excludes personal tourist bookings, other hosts and other dates',
    () {
      final rows = <Map<String, dynamic>>[
        {
          'id': 'own',
          'provider_id': 'mine',
          'experience_id': 'coffee',
          'date': '2026-11-23',
        },
        {
          'id': 'tourist',
          'provider_id': 'other',
          'user_id': 'me',
          'experience_id': 'culture',
          'date': '2026-11-23',
        },
        {
          'id': 'tomorrow',
          'provider_id': 'mine',
          'experience_id': 'coffee',
          'date': '2026-11-24',
        },
        {
          'id': 'otherplan',
          'provider_id': 'mine',
          'experience_id': 'nature',
          'date': '2026-11-23',
        },
      ];
      expect(
        hostAgendaForDate(
          rows,
          'mine',
          DateTime(2026, 11, 23),
        ).map((r) => r['id']),
        ['own', 'otherplan'],
      );
      expect(
        hostAgendaForDate(
          rows,
          'mine',
          DateTime(2026, 11, 23),
          planId: 'coffee',
        ).map((r) => r['id']),
        ['own'],
      );
    },
  );
  testWidgets(
    'host plans show explicit editing and lifecycle actions with status filters',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HostPlanList(
                hostId: 'mine',
                loader: () async => [
                  {
                    'id': 'one',
                    'title': 'Café publicado',
                    'status': 'published',
                    'price_amount': 65000,
                  },
                  {
                    'id': 'two',
                    'title': 'Naturaleza en borrador',
                    'status': 'draft',
                    'price_amount': 55000,
                  },
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar plan'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Opciones de Café publicado'));
      await tester.pumpAndSettle();
      expect(find.text('Pausar'), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Borrador'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Borrador'));
      await tester.pumpAndSettle();
      expect(find.text('Naturaleza en borrador'), findsOneWidget);
      expect(find.text('Café publicado'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('host calendar shows only participants of offered plans', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: HostAgendaPage(
          hostId: 'mine',
          initialDate: DateTime(2026, 11, 23),
          loader: () async => [
            {
              'id': 'one',
              'provider_id': 'mine',
              'experience_id': 'coffee',
              'experience_title': 'Café ofrecido',
              'date': '2026-11-23',
              'status': 'accepted',
              'adults': 2,
              'minors': 1,
            },
            {
              'id': 'two',
              'provider_id': 'other',
              'experience_id': 'tourist',
              'experience_title': 'Mi reserva como turista',
              'date': '2026-11-23',
              'status': 'accepted',
              'adults': 9,
              'minors': 0,
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('1 inscripciones activas · 3 participantes'),
      findsOneWidget,
    );
    expect(find.text('Café ofrecido'), findsWidgets);
    expect(find.text('Mi reserva como turista'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
