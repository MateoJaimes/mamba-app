class ExperienceSchedule {
  const ExperienceSchedule({
    required this.id,
    required this.experienceId,
    required this.startTime,
    required this.endTime,
    required this.availableSlots,
    required this.statusId,
  });

  final String id;

  final String experienceId;

  final DateTime startTime;

  final DateTime endTime;

  final int availableSlots;

  final String statusId;
}
