enum ColombianRatingTarget { experience, host }

/// Numeric scores remain useful for sorting and aggregates; the UI uses
/// Colombian-language labels instead of star icons.
enum ColombianRating {
  noFueLoMio(1, 'No fue lo mío'),
  buenParche(2, 'Buen parche'),
  superParche(3, 'Súper parche'),
  planazo(4, 'Planazo'),
  unaChimba(5, '¡Una chimba!');

  const ColombianRating(this.score, this.label);

  final int score;
  final String label;

  static ColombianRating fromScore(int score) => values.firstWhere(
    (rating) => rating.score == score,
    orElse: () => throw RangeError.range(score, 1, 5, 'score'),
  );
}

enum HostServiceRating {
  noVolveria(1, 'No volvería'),
  atencionNormal(2, 'Atención normal'),
  buenAnfitrion(3, 'Buen anfitrión'),
  muyBuenaEnergia(4, 'Muy buena energía'),
  seLucio(5, 'Se lució');

  const HostServiceRating(this.score, this.label);

  final int score;
  final String label;
}
