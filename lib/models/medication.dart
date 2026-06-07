class Medication {
  Medication({required this.nome, this.dose = '', List<String>? periodos})
      : periodos = periodos ?? <String>[];

  final String nome;
  final String dose;
  final List<String> periodos;

  Medication copyWith({String? nome, String? dose, List<String>? periodos}) {
    return Medication(
      nome: nome ?? this.nome,
      dose: dose ?? this.dose,
      periodos: periodos != null
          ? List<String>.from(periodos)
          : List<String>.from(this.periodos),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nome': nome,
        'dose': dose,
        'periodos': periodos,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        nome: (json['nome'] as String?) ?? '',
        dose: (json['dose'] as String?) ?? '',
        periodos: ((json['periodos'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
      );

  String get display {
    final StringBuffer b = StringBuffer(nome);
    if (dose.isNotEmpty) b.write(' — $dose');
    if (periodos.isNotEmpty) b.write(' (${periodos.join(', ')})');
    return b.toString();
  }
}
