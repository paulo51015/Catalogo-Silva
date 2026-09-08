enum CategoriaPeca {
  suspensao,
  freios,
  motor,
  direcao,
  eletrica,
  arrefecimento,
  embreagem,
  filtros,
  correias,
  rolamentos,
  injecao,
  ignicao,
  lubrificacao,
  outros,
}

extension CategoriaPecaExtension on CategoriaPeca {
  String get nomeExibicao {
    switch (this) {
      case CategoriaPeca.suspensao: return 'Suspensão';
      case CategoriaPeca.freios: return 'Freios';
      case CategoriaPeca.motor: return 'Motor';
      case CategoriaPeca.direcao: return 'Direção';
      case CategoriaPeca.eletrica: return 'Elétrica';
      case CategoriaPeca.arrefecimento: return 'Arrefecimento';
      case CategoriaPeca.embreagem: return 'Embreagem';
      case CategoriaPeca.filtros: return 'Filtros';
      case CategoriaPeca.correias: return 'Correias';
      case CategoriaPeca.rolamentos: return 'Rolamentos';
      case CategoriaPeca.injecao: return 'Injeção';
      case CategoriaPeca.ignicao: return 'Ignição';
      case CategoriaPeca.lubrificacao: return 'Lubrificação';
      case CategoriaPeca.outros: return 'Outros';
    }
  }

  String get icone {
    switch (this) {
      case CategoriaPeca.suspensao: return '🛞';
      case CategoriaPeca.freios: return '🛑';
      case CategoriaPeca.motor: return '⚙️';
      case CategoriaPeca.direcao: return '🎯';
      case CategoriaPeca.eletrica: return '⚡';
      case CategoriaPeca.arrefecimento: return '❄️';
      case CategoriaPeca.embreagem: return '🕹️';
      case CategoriaPeca.filtros: return '🧪';
      case CategoriaPeca.correias: return '🔄';
      case CategoriaPeca.rolamentos: return '🔘';
      case CategoriaPeca.injecao: return '⛽';
      case CategoriaPeca.ignicao: return '🔥';
      case CategoriaPeca.lubrificacao: return '🛢️';
      case CategoriaPeca.outros: return '📦';
    }
  }
}

/// Modelo que representa uma Peça no catálogo automotivo.
class PecaModel {
  final String id;
  final String descricao; // ex: Amortecedor Dianteiro, Pastilha de Freio Dianteira, Filtro de Óleo
  final CategoriaPeca categoria;
  final String codigoOem; // ex: 48510-02880 (Toyota), 5U0413031 (VW)
  final String montadoraOrigem; // ex: Toyota, VW, GM, Fiat
  final String posicao; // ex: Dianteiro, Traseiro, Superior, Inferior
  final String eixo; // ex: Dianteiro, Traseiro
  final String lado; // ex: Direito, Esquerdo, Ambos (Par)
  final String observacoesTecnicas;

  const PecaModel({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.codigoOem,
    required this.montadoraOrigem,
    this.posicao = 'Dianteiro',
    this.eixo = 'Dianteiro',
    this.lado = 'Ambos',
    this.observacoesTecnicas = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'categoria': categoria.name,
      'codigoOem': codigoOem,
      'montadoraOrigem': montadoraOrigem,
      'posicao': posicao,
      'eixo': eixo,
      'lado': lado,
      'observacoesTecnicas': observacoesTecnicas,
    };
  }

  factory PecaModel.fromMap(Map<String, dynamic> map) {
    return PecaModel(
      id: map['id'] ?? '',
      descricao: map['descricao'] ?? '',
      categoria: CategoriaPeca.values.firstWhere(
        (c) => c.name == map['categoria'],
        orElse: () => CategoriaPeca.outros,
      ),
      codigoOem: map['codigoOem'] ?? '',
      montadoraOrigem: map['montadoraOrigem'] ?? '',
      posicao: map['posicao'] ?? 'Dianteiro',
      eixo: map['eixo'] ?? 'Dianteiro',
      lado: map['lado'] ?? 'Ambos',
      observacoesTecnicas: map['observacoesTecnicas'] ?? '',
    );
  }
}
