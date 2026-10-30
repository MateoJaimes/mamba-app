class ExperiencePrice {
  const ExperiencePrice({
    required this.id,
    required this.experienceId,
    required this.currencyId,
    required this.adultPrice,
    required this.childPrice,
    required this.infantPrice,
  });

  final String id;

  final String experienceId;

  final String currencyId;

  final double adultPrice;

  final double? childPrice;

  final double? infantPrice;
}
