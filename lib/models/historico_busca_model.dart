/// Registro de histórico de pesquisa do colaborador no balcão.
class HistoricoBuscaModel {
  final String id;
  final String usuarioId;
  final String termoPesquisa;
  final int totalResultados;
  final DateTime dataHora;

  const HistoricoBuscaModel({
    required this.id,
    required this.usuarioId,
    required this.termoPesquisa,
    required this.totalResultados,
    required this.dataHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'termoPesquisa': termoPesquisa,
      'totalResultados': totalResultados,
      'dataHora': dataHora.toIso8601String(),
    };
  }

  factory HistoricoBuscaModel.fromMap(Map<String, dynamic> map) {
    return HistoricoBuscaModel(
      id: map['id'] ?? '',
      usuarioId: map['usuarioId'] ?? '',
      termoPesquisa: map['termoPesquisa'] ?? '',
      totalResultados: map['totalResultados'] ?? 0,
      dataHora: DateTime.tryParse(map['dataHora'] ?? '') ?? DateTime.now(),
    );
  }
}
