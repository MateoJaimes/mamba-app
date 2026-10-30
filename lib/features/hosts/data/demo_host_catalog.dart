/// Local demo content shared by feed, search and host profiles until the API
/// and persistence layer is available.
abstract final class DemoHostCatalog {
  static const hosts = <Map<String, String>>[
    {
      'id': 'guias-de-la-13',
      'name': 'Guías de la 13',
      'handle': '@guiasdela13',
      'location': 'Medellín, Antioquia',
      'bio':
          'Historias, arte urbano y cultura local contadas por quienes vivimos la Comuna 13. ¡Vení a parchar con nosotros!',
      'host_rating': 'Se lució',
      'verified': 'true',
      'joined': 'Desde 2023',
      'reviews': '124',
      'followers': '1280',
      'avatar':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300',
      'cover':
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1200',
    },
    {
      'id': 'origen-cafe',
      'name': 'Origen Café',
      'handle': '@origencafe',
      'location': 'El Poblado, Medellín',
      'bio':
          'Café de origen, historias de finca y experiencias para disfrutar sin afán. Del grano a la taza.',
      'host_rating': 'Muy buena energía',
      'verified': 'true',
      'joined': 'Desde 2024',
      'reviews': '87',
      'followers': '856',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
      'cover':
          'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=1200',
    },
    {
      'id': 'rutas-de-antioquia',
      'name': 'Rutas de Antioquia',
      'handle': '@rutasdeantioquia',
      'location': 'Envigado, Antioquia',
      'bio':
          'Montaña, naturaleza y caminos para volver a respirar. Guías locales y grupos pequeños.',
      'host_rating': 'Buen anfitrión',
      'verified': 'false',
      'joined': 'Desde 2024',
      'reviews': '51',
      'followers': '2430',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300',
      'cover':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200',
    },
  ];

  static const experiences = <Map<String, dynamic>>[
    {
      'id': 'comuna-13',
      'provider_id': 'guias-de-la-13',
      'title': 'Explora la Comuna 13',
      'provider': 'Guías de la 13',
      'description':
          'Descubre la historia, cultura y arte urbano de uno de los lugares más representativos de Medellín.',
      'location': 'Comuna 13, Medellín',
      'category': 'Cultura',
      'price': '\$85.000',
      'experience_rating': '¡Una chimba!',
      'host_rating': 'Se lució',
      'reviews': '124',
      'duration': '3 horas',
      'max_people': 10,
      'meeting_point': 'Escaleras eléctricas de la Comuna 13',
      'latitude': 6.2557,
      'longitude': -75.6173,
      'includes':
          'Guía local, recorrido de arte urbano y una bebida tradicional.',
      'requirements':
          'Usa zapatos cómodos, protector solar y trae muchas ganas de conocer.',
      'age_policy': 'all_ages',
      'minimum_age': 0,
      'minor_supervision_required': true,
      'age_policy_note':
          'Menores de 18 años pueden asistir acompañados por una persona adulta responsable.',
      'images': [
        'https://images.unsplash.com/photo-1583531352515-888e8f7b3c7c',
        'https://images.unsplash.com/photo-1533105079780-92b9be482077',
        'https://images.unsplash.com/photo-1519501025264-65ba15a82390',
      ],
    },
    {
      'id': 'cafe-especialidad',
      'provider_id': 'origen-cafe',
      'title': 'Café de especialidad',
      'provider': 'Origen Café',
      'description':
          'Conoce el proceso detrás de un excelente café y disfruta una experiencia auténtica en Medellín.',
      'location': 'El Poblado, Medellín',
      'category': 'Gastronomía',
      'price': '\$65.000',
      'experience_rating': 'Planazo',
      'host_rating': 'Muy buena energía',
      'reviews': '87',
      'duration': '2 horas',
      'max_people': 8,
      'meeting_point': 'Café Origen, El Poblado',
      'latitude': 6.2088,
      'longitude': -75.5679,
      'includes': 'Cata guiada de tres cafés y método de preparación.',
      'requirements': 'No necesitas experiencia previa con café.',
      'age_policy': 'minimum_age',
      'minimum_age': 12,
      'minor_supervision_required': true,
      'age_policy_note':
          'Desde los 12 años. Menores de 18 años deben asistir con una persona adulta responsable.',
      'images': [
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
        'https://images.unsplash.com/photo-1447933601403-0c6688de566e',
      ],
    },
    {
      'id': 'senderismo-montanas',
      'provider_id': 'rutas-de-antioquia',
      'title': 'Senderismo en las montañas',
      'provider': 'Rutas de Antioquia',
      'description':
          'Una experiencia al aire libre para descubrir los paisajes naturales que rodean el Valle de Aburrá.',
      'location': 'Envigado, Antioquia',
      'category': 'Aventura',
      'price': '\$95.000',
      'experience_rating': 'Súper parche',
      'host_rating': 'Buen anfitrión',
      'reviews': '51',
      'duration': '5 horas',
      'max_people': 8,
      'meeting_point': 'Parque principal de Envigado',
      'latitude': 6.1711,
      'longitude': -75.5871,
      'includes': 'Guía local, hidratación y pausa para disfrutar el paisaje.',
      'requirements': 'Lleva ropa cómoda, agua y calzado para caminar.',
      'age_policy': 'adults_only',
      'minimum_age': 18,
      'minor_supervision_required': false,
      'age_policy_note': 'Esta ruta es solo para personas mayores de 18 años.',
      'images': ['https://images.unsplash.com/photo-1551632811-561732d1e306'],
    },
  ];

  static const reviews = <Map<String, String>>[
    {
      'host_id': 'guias-de-la-13',
      'author': 'Valentina R.',
      'experience': 'Explora la Comuna 13',
      'date': 'Hace 2 semanas',
      'rating': 'Se lució',
      'comment':
          'Se nota el amor por el barrio. La pasamos buenísimo y aprendimos un montón.',
    },
    {
      'host_id': 'guias-de-la-13',
      'author': 'Andrés M.',
      'experience': 'Explora la Comuna 13',
      'date': 'Hace 1 mes',
      'rating': 'Muy buena energía',
      'comment':
          'Un recorrido cercano, respetuoso y lleno de historias que no conocíamos.',
    },
    {
      'host_id': 'origen-cafe',
      'author': 'Camila P.',
      'experience': 'Café de especialidad',
      'date': 'Hace 5 días',
      'rating': 'Se lució',
      'comment':
          'Aprendí a reconocer sabores y el anfitrión hizo todo muy fácil y divertido.',
    },
    {
      'host_id': 'origen-cafe',
      'author': 'Juan D.',
      'experience': 'Café de especialidad',
      'date': 'Hace 3 semanas',
      'rating': 'Buen anfitrión',
      'comment': 'Un plan tranquilo, buen café y una explicación muy completa.',
    },
    {
      'host_id': 'rutas-de-antioquia',
      'author': 'Sofía G.',
      'experience': 'Senderismo en las montañas',
      'date': 'Hace 1 semana',
      'rating': 'Muy buena energía',
      'comment':
          'El guía estuvo pendiente del grupo y nos llevó por unos paisajes increíbles.',
    },
    {
      'host_id': 'rutas-de-antioquia',
      'author': 'Mateo C.',
      'experience': 'Senderismo en las montañas',
      'date': 'Hace 1 mes',
      'rating': 'Buen anfitrión',
      'comment':
          'Buena organización y recomendaciones útiles para disfrutar la caminata.',
    },
  ];

  static Map<String, String>? hostById(String id) {
    for (final host in hosts) {
      if (host['id'] == id) return host;
    }
    return null;
  }

  static List<Map<String, dynamic>> experiencesByHost(String id) =>
      experiences.where((item) => item['provider_id'] == id).toList();

  static List<Map<String, String>> reviewsByHost(String id) =>
      reviews.where((review) => review['host_id'] == id).toList();

  static Map<String, dynamic>? experienceById(String id) {
    for (final experience in experiences) {
      if (experience['id'] == id) return experience;
    }
    return null;
  }
}
