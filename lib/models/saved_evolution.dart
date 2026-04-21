class SavedEvolution {
  SavedEvolution({
    required this.id,
    required this.date,
    required this.time,
    required this.patientName,
    required this.text,
  });

  final String id;
  final String date;
  final String time;
  final String patientName;
  final String text;

  SavedEvolution copyWith({
    String? id,
    String? date,
    String? time,
    String? patientName,
    String? text,
  }) {
    return SavedEvolution(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      patientName: patientName ?? this.patientName,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date,
        'time': time,
        'patientName': patientName,
        'text': text,
      };

  factory SavedEvolution.fromJson(Map<String, dynamic> json) => SavedEvolution(
        id: (json['id'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        time: (json['time'] as String?) ?? '',
        patientName: (json['patientName'] as String?) ?? '',
        text: (json['text'] as String?) ?? '',
      );
}
