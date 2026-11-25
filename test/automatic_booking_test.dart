import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/features/bookings/data/local_booking_store.dart';
import 'package:mapo_app/features/hosts/presentation/pages/manage_bookings_page.dart';
import 'package:mapo_app/features/experiences/presentation/pages/experience_detail_page.dart';
import 'package:mapo_app/features/hosts/data/demo_host_catalog.dart';

void main() {
  test(
    'confirmed server status is labelled confirmed',
    () => expect(bookingStatusLabel('accepted'), 'Confirmada'),
  );
  test(
    'a device draft is never presented as an automatic confirmation',
    () async {
      await expectLater(
        LocalBookingStore.create(
          experience: const {},
          date: DateTime.now(),
          adults: 1,
          minors: 0,
          minorsSupervisionConfirmed: true,
          minimumAgeConfirmed: true,
        ),
        throwsStateError,
      );
    },
  );
  testWidgets(
    'booking sheet explains automatic confirmation and direct in-person payment',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: ExperienceDetailPage(
            experienceId: '${DemoHostCatalog.experiences.first['id']}',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Me apunto'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Confirmar mi inscripción'), findsOneWidget);
      expect(
        find.text(
          'Confirmación automática si hay cupo. Paga presencialmente al anfitrión; la app no cobra.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('pendiente de confirmación del anfitrión'),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Confirmar mi inscripción'));
      await tester.tap(find.text('Confirmar mi inscripción'));
      await tester.pump();
      expect(
        find.text(
          'Inicia sesión y conéctate a internet para confirmar tu inscripción.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('¡Inscripción confirmada!'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
