abstract final class PlanCategories {
  static const labels = <String, String>{
    'Aventura': 'Aventura',
    'Cultura': 'Cultura',
    'Gastronomía': 'Comida y café',
    'Naturaleza': 'Naturaleza',
    'Bienestar': 'Bienestar',
    'Deporte': 'Deporte',
    'Arte': 'Arte',
    'Música': 'Música',
    'Nocturno': 'Vida nocturna',
    'Familia': 'En familia',
    'Talleres': 'Talleres',
    'Rural': 'Turismo rural',
    'Historia': 'Historia',
    'Otro': 'Otro',
  };
  static List<String> of(Map<String, dynamic> plan) => List<String>.from(
    plan['categories'] as List? ?? [plan['category'] ?? 'Otro'],
  );
}
