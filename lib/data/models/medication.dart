/// Represents a medication entry in the user's schedule.
///
/// This is a temporary mock model. Field names do NOT represent the final
/// PostgreSQL/Supabase schema.
class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.status,
    required this.note,
    this.iconCodePoint = 0xe3a3, // Icons.medication_rounded
    this.colorValue = 0xFF00674F, // Emerald
  });

  final String id;
  final String name;
  final String dose;
  final String time;
  final MedStatus status;
  final String note;
  final int iconCodePoint;
  final int colorValue;

  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    String? time,
    MedStatus? status,
    String? note,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      time: time ?? this.time,
      status: status ?? this.status,
      note: note ?? this.note,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

enum MedStatus { taken, pending, missed }

/// Represents a single dose log entry for history.
class DoseLog {
  const DoseLog({
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.status,
    required this.loggedAt,
  });

  final String medicationId;
  final String medicationName;
  final String dose;
  final MedStatus status;
  final DateTime loggedAt;
}
