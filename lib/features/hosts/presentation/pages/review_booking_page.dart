import 'package:flutter/material.dart';
import '../../../../core/services/account_service.dart';
import '../../../../shared/widgets/data_form_page.dart';

class ReviewBookingPage extends StatelessWidget {
  const ReviewBookingPage({super.key, required this.booking});
  final Map<String, dynamic> booking;
  @override
  Widget build(BuildContext context) => DataFormPage(
    title: 'Cuéntanos cómo te fue',
    saveLabel: 'Publicar reseña',
    description:
        'Tu opinión ayuda a elegir el próximo plan. Puedes publicar una reseña por inscripción completada.',
    initial: const {'experience_score': '4', 'host_score': '4'},
    fields: const [
      DataField(
        'experience_score',
        'La experiencia',
        choices: {
          '1': 'No fue lo mío',
          '2': 'Buen parche',
          '3': 'Súper parche',
          '4': 'Planazo',
          '5': '¡Una chimba!',
        },
      ),
      DataField(
        'host_score',
        'El anfitrión',
        choices: {
          '1': 'No volvería',
          '2': 'Atención normal',
          '3': 'Buen anfitrión',
          '4': 'Muy buena energía',
          '5': 'Se lució',
        },
      ),
      DataField('comment', '¿Qué te gustaría compartir?', lines: 5),
    ],
    onSave: (data) async {
      await AccountService.client.from('reviews').insert({
        'booking_id': booking['id'],
        'reviewer_id': AccountService.userId,
        'experience_id': booking['experience_id'],
        'host_profile_id': booking['provider_id'],
        'experience_score': int.parse(data['experience_score'] as String),
        'host_score': int.parse(data['host_score'] as String),
        'comment': data['comment'],
      });
    },
  );
}
