import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/core/services/account_service.dart';
import 'package:mapo_app/features/auth/presentation/pages/auth_page.dart';
import 'package:mapo_app/shared/widgets/data_form_page.dart';

void main() {
  test('host permissions require both trusted role and approved profile', () {
    expect(
      const AccountSnapshot({}, {'tourist'}, {'status': 'approved'}, {
        'approved_at': 'today',
      }).canHost,
      isFalse,
    );
    expect(
      const AccountSnapshot({}, {'host'}, {}, {'approved_at': null}).canHost,
      isFalse,
    );
    expect(
      const AccountSnapshot({}, {'host'}, {}, {'approved_at': 'today'}).canHost,
      isTrue,
    );
    expect(
      const AccountSnapshot(
        {'account_intent': 'admin'},
        {'tourist'},
        null,
        null,
      ).isAdmin,
      isFalse,
    );
  });
  testWidgets(
    'register offers tourist and host without granting publishing access',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: AuthPage(authConfigured: true)),
      );
      final register = find.text('Regístrate');
      await tester.ensureVisible(register);
      await tester.pumpAndSettle();
      await tester.tap(register);
      await tester.pumpAndSettle();
      expect(find.text('Turista'), findsOneWidget);
      expect(find.text('Anfitrión'), findsOneWidget);
      await tester.ensureVisible(find.text('Anfitrión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anfitrión'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Podrás publicar cuando MAPO la apruebe'),
        findsOneWidget,
      );
    },
  );
  testWidgets('empty form never performs a write', (tester) async {
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DataFormPage(
          title: 'Perfil',
          fields: const [DataField('name', 'Nombre')],
          onSave: (_) async {
            writes++;
          },
        ),
      ),
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Completa este campo'), findsOneWidget);
  });
}
