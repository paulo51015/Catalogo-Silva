/// Resultado estatístico da validação e importação de planilhas Excel / CSV.
class ImportResultModel {
  final int totalLinhas;
  final int registrosNovos;
  final int registrosAtualizados;
  final int registrosDuplicados;
  final int registrosComErro;
  final List<String> logErros;
  final List<Map<String, dynamic>> registrosPrevia;

  const ImportResultModel({
    required this.totalLinhas,
    required this.registrosNovos,
    required this.registrosAtualizados,
    required this.registrosDuplicados,
    required this.registrosComErro,
    this.logErros = const [],
    this.registrosPrevia = const [],
  });

  bool get temErros => registrosComErro > 0;
  bool get podeImportar => (registrosNovos + registrosAtualizados) > 0;
}
