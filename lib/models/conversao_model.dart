import 'fabricante_model.dart';
import 'peca_model.dart';
import 'veiculo_model.dart';

enum StatusConfiabilidade {
  confirmada, // 🟢 Confirmada por catálogo de fabricante
  necessitaRevisao, // 🟡 Necessita revisão física/conferência
  naoConfirmada, // 🔴 Não confirmada (apenas sugestão)
}

extension StatusConfiabilidadeExtension on StatusConfiabilidade {
  String get nomeExibicao {
    switch (this) {
      case StatusConfiabilidade.confirmada:
        return 'Confirmada';
      case StatusConfiabilidade.necessitaRevisao:
        return 'Necessita Revisão';
      case StatusConfiabilidade.naoConfirmada:
        return 'Não Confirmada';
    }
  }

  String get icone {
    switch (this) {
      case StatusConfiabilidade.confirmada:
        return '✅';
      case StatusConfiabilidade.necessitaRevisao:
        return '⚠️';
      case StatusConfiabilidade.naoConfirmada:
        return '❌';
    }
  }
}

enum FonteConversao {
  catalogoFabricante, // Catálogo Oficial (COFAP, Monroe, etc.)
  fornecedor, // Informação de Fornecedor / Distribuidor
  catalogoInterno, // Histórico de Aplicação Centro Automotivo Silva
  cadastroManual, // Cadastro manual por colaborador
}

extension FonteConversaoExtension on FonteConversao {
  String get nomeExibicao {
    switch (this) {
      case FonteConversao.catalogoFabricante:
        return 'Catálogo do Fabricante';
      case FonteConversao.fornecedor:
        return 'Fornecedor / Distribuidor';
      case FonteConversao.catalogoInterno:
        return 'Catálogo Interno Silva';
      case FonteConversao.cadastroManual:
        return 'Cadastro Manual';
    }
  }
}

/// Entidade Central de Conversão de Peça para Veículo no Centro Automotivo Silva.
class ConversaoModel {
  final String id;
  final PecaModel peca;
  final VeiculoModel veiculo;
  final List<CodigoEquivalenteItem> equivalentes; // COFAP, Monroe, Nakata, KYB, Bosch, etc.
  final StatusConfiabilidade status;
  final FonteConversao fonte;
  final String observacaoCompatibilidade;
  final String usuarioAtualizacao;
  final DateTime dataAtualizacao;
  final bool isFavorito;

  const ConversaoModel({
    required this.id,
    required this.peca,
    required this.veiculo,
    required this.equivalentes,
    this.status = StatusConfiabilidade.confirmada,
    this.fonte = FonteConversao.catalogoFabricante,
    this.observacaoCompatibilidade = '',
    this.usuarioAtualizacao = 'Administrador',
    required this.dataAtualizacao,
    this.isFavorito = false,
  });

  ConversaoModel copyWith({
    String? id,
    PecaModel? peca,
    VeiculoModel? veiculo,
    List<CodigoEquivalenteItem>? equivalentes,
    StatusConfiabilidade? status,
    FonteConversao? fonte,
    String? observacaoCompatibilidade,
    String? usuarioAtualizacao,
    DateTime? dataAtualizacao,
    bool? isFavorito,
  }) {
    return ConversaoModel(
      id: id ?? this.id,
      peca: peca ?? this.peca,
      veiculo: veiculo ?? this.veiculo,
      equivalentes: equivalentes ?? this.equivalentes,
      status: status ?? this.status,
      fonte: fonte ?? this.fonte,
      observacaoCompatibilidade: observacaoCompatibilidade ?? this.observacaoCompatibilidade,
      usuarioAtualizacao: usuarioAtualizacao ?? this.usuarioAtualizacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      isFavorito: isFavorito ?? this.isFavorito,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peca': peca.toMap(),
      'veiculo': veiculo.toMap(),
      'equivalentes': equivalentes.map((e) => e.toMap()).toList(),
      'status': status.name,
      'fonte': fonte.name,
      'observacaoCompatibilidade': observacaoCompatibilidade,
      'usuarioAtualizacao': usuarioAtualizacao,
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'isFavorito': isFavorito,
    };
  }

  factory ConversaoModel.fromMap(Map<String, dynamic> map) {
    return ConversaoModel(
      id: map['id'] ?? '',
      peca: PecaModel.fromMap(map['peca'] ?? {}),
      veiculo: VeiculoModel.fromMap(map['veiculo'] ?? {}),
      equivalentes: (map['equivalentes'] as List? ?? [])
          .map((item) => CodigoEquivalenteItem.fromMap(item))
          .toList(),
      status: StatusConfiabilidade.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StatusConfiabilidade.confirmada,
      ),
      fonte: FonteConversao.values.firstWhere(
        (f) => f.name == map['fonte'],
        orElse: () => FonteConversao.catalogoFabricante,
      ),
      observacaoCompatibilidade: map['observacaoCompatibilidade'] ?? '',
      usuarioAtualizacao: map['usuarioAtualizacao'] ?? 'Sistema',
      dataAtualizacao: DateTime.tryParse(map['dataAtualizacao'] ?? '') ?? DateTime.now(),
      isFavorito: map['isFavorito'] ?? false,
    );
  }
}
