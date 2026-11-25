import 'package:flutter/material.dart';
import '../../../../core/services/account_service.dart';
import '../../../../core/services/plan_categories.dart';
import '../../../../shared/widgets/data_form_page.dart';

String experienceStatusLabel(String status) => switch (status) {
  'published' => 'Publicada',
  'paused' => 'En pausa',
  'archived' => 'Archivada',
  _ => 'Borrador',
};

class ExperienceEditorPage extends StatefulWidget {
  const ExperienceEditorPage({super.key, this.experience});
  final Map<String, dynamic>? experience;
  @override
  State<ExperienceEditorPage> createState() => _ExperienceEditorPageState();
}

class _ExperienceEditorPageState extends State<ExperienceEditorPage> {
  @override
  Widget build(BuildContext context) {
    final e = widget.experience;
    final images = (e?['experience_images'] as List? ?? []).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return DataFormPage(
      title: e == null ? 'Crear plan' : 'Editar plan',
      description:
          'Dale forma a tu próxima experiencia. Puedes guardarla como borrador y publicarla cuando esté lista.',
      initial: {
        'duration_minutes': 120,
        'price_amount': 0,
        'maximum_people': 10,
        'age_policy': 'all_ages',
        'minimum_age': 0,
        'status': 'draft',
        ...?e,
        'categories': e?['categories'] ?? [e?['category'] ?? 'Naturaleza'],
        'images': images.map((i) => i['image_url']).join('\n'),
      },
      fields: const [
        DataField('title', 'Nombre de tu plan', section: 'El plan'),
        DataField(
          'description',
          'Descripción (mínimo 30 caracteres)',
          lines: 5,
        ),
        DataField(
          'categories',
          'Categorías',
          choices: PlanCategories.labels,
          multiple: true,
        ),
        DataField('images', 'Fotos', section: 'Fotos'),
        DataField('location_label', 'Ciudad y sector', section: 'El encuentro'),
        DataField('meeting_point', 'Punto de encuentro'),
        DataField('latitude', 'Latitud', number: true),
        DataField('longitude', 'Longitud', number: true),
        DataField(
          'duration_minutes',
          'Duración en minutos',
          number: true,
          section: 'Duración, precio y cupos',
        ),
        DataField('price_amount', 'Precio por persona en COP', number: true),
        DataField('maximum_people', 'Cupos por día', number: true),
        DataField(
          'age_policy',
          '¿Quiénes pueden participar?',
          section: 'Antes de ir',
          choices: {
            'all_ages': 'Todas las edades',
            'adults_only': 'Solo adultos',
            'minimum_age': 'Con edad mínima',
          },
        ),
        DataField('minimum_age', 'Edad mínima', number: true),
        DataField('includes', 'Qué incluye', lines: 3, required: false),
        DataField(
          'requirements',
          'Qué deben llevar',
          lines: 3,
          required: false,
        ),
        DataField(
          'status',
          'Estado de publicación',
          section: 'Publicación',
          choices: {
            'draft': 'Borrador',
            'published': 'Publicada',
            'paused': 'En pausa',
            'archived': 'Archivada',
          },
        ),
      ],
      onSave: (data) async {
        await AccountService.action('save_experience', {
          ...data,
          'category': (data['categories'] as List).first,
          if (e != null) 'id': e['id'],
          'images': (data['images'] as String)
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        });
      },
    );
  }
}
