/// Registro de auditoria para rastrear quem alterou, inseriu ou importou conversões e peças.
class AuditoriaModel {
  final String id;
  final String usuarioNome;
  final String acao; // 'INSERÇÃO', 'EDIÇÃO', 'EXCLUSÃO', 'IMPORTAÇÃO PLANILHA'
  final String entidade; // 'Conversão', 'Peça', 'Veículo', 'Marca'
  final String descricao;
  final DateTime dataHora;

  const AuditoriaModel({
    required this.id,
    required this.usuarioNome,
    required this.acao,
    required this.entidade,
    required this.descricao,
    required this.dataHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioNome': usuarioNome,
      'acao': acao,
      'entidade': entidade,
      'descricao': descricao,
      'dataHora': dataHora.toIso8601String(),
    };
  }

  factory AuditoriaModel.fromMap(Map<String, dynamic> map) {
    return AuditoriaModel(
      id: map['id'] ?? '',
      usuarioNome: map['usuarioNome'] ?? '',
      acao: map['acao'] ?? '',
      entidade: map['entidade'] ?? '',
      descricao: map['descricao'] ?? '',
      dataHora: DateTime.tryParse(map['dataHora'] ?? '') ?? DateTime.now(),
    );
  }
}
