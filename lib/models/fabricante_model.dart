/// Modelo que representa um Fabricante / Marca de Peças Paralelas ou OEM.
class FabricanteModel {
  final String id;
  final String nome; // ex: COFAP, MONROE, NAKATA, KYB, TRW, FRAS-LE, BOSCH, MAHLE, NGK, SKF, VALEO, LUK
  final String paisOrigem;
  final bool isOem; // true se for montadora original
  final bool ativo;

  const FabricanteModel({
    required this.id,
    required this.nome,
    this.paisOrigem = 'Brasil',
    this.isOem = false,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'paisOrigem': paisOrigem,
      'isOem': isOem,
      'ativo': ativo,
    };
  }

  factory FabricanteModel.fromMap(Map<String, dynamic> map) {
    return FabricanteModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      paisOrigem: map['paisOrigem'] ?? 'Brasil',
      isOem: map['isOem'] ?? false,
      ativo: map['ativo'] ?? true,
    );
  }
}

/// Item de Código de uma Marca Paralela vinculada a uma conversão.
class CodigoEquivalenteItem {
  final String fabricanteNome; // ex: COFAP
  final String codigo; // ex: GP33256
  final String? descricaoEspecifica;
  final String? linha; // ex: Turbogás, Heavy Duty, Cerâmica

  const CodigoEquivalenteItem({
    required this.fabricanteNome,
    required this.codigo,
    this.descricaoEspecifica,
    this.linha,
  });

  Map<String, dynamic> toMap() {
    return {
      'fabricanteNome': fabricanteNome,
      'codigo': codigo,
      'descricaoEspecifica': descricaoEspecifica,
      'linha': linha,
    };
  }

  factory CodigoEquivalenteItem.fromMap(Map<String, dynamic> map) {
    return CodigoEquivalenteItem(
      fabricanteNome: map['fabricanteNome'] ?? '',
      codigo: map['codigo'] ?? '',
      descricaoEspecifica: map['descricaoEspecifica'],
      linha: map['linha'],
    );
  }
}
