class Infusion {
  Infusion({required this.nome, this.detalhe = ''});

  final String nome;
  final String detalhe;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nome': nome,
        'det': detalhe,
      };

  factory Infusion.fromJson(Map<String, dynamic> json) => Infusion(
        nome: (json['nome'] as String?) ?? '',
        detalhe: (json['det'] as String?) ?? '',
      );

  String get display =>
      detalhe.isEmpty ? nome : '$nome — $detalhe';
}
