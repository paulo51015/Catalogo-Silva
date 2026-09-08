import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/auditoria_model.dart';
import '../models/conversao_model.dart';
import '../models/fabricante_model.dart';
import '../models/import_result_model.dart';
import '../models/peca_model.dart';
import '../models/veiculo_model.dart';
import 'audit_service.dart';
import 'database_service.dart';

enum DuplicidadeEstrategia {
  atualizar, // Atualiza a conversão existente com os novos dados
  ignorar, // Não altera registros duplicados existentes
  criarNovo, // Cria novo registro adicional
}

/// Serviço de Importação e Validação de Planilhas de Catálogos (Excel / CSV).
class ImportService {
  final DatabaseService _db;
  final AuditService _audit;

  ImportService(this._db, this._audit);

  /// Processa o conteúdo de um arquivo CSV ou texto delimitado e gera uma prévia com estatísticas.
  ImportResultModel analisarPlanilha({
    required String rawContent,
    required Map<String, int> mapeamentoColunas, // 'codigo': 0, 'marca': 1, 'modelo': 2, etc.
  }) {
    final List<String> logErros = [];
    final List<Map<String, dynamic>> previaRegistros = [];

    int novos = 0;
    int atualizados = 0;
    int duplicados = 0;
    int erros = 0;

    try {
      final rows = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
        shouldParseNumbers: false,
      ).convert(rawContent);

      if (rows.isEmpty) {
        return const ImportResultModel(
          totalLinhas: 0,
          registrosNovos: 0,
          registrosAtualizados: 0,
          registrosDuplicados: 0,
          registrosComErro: 1,
          logErros: ['O arquivo selecionado está vazio.'],
        );
      }

      // Pula a linha 0 de cabeçalho se houver
      final dataRows = rows.length > 1 ? rows.sublist(1) : rows;

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final linhaNumero = i + 2;

        try {
          final codigo = _obterCampo(row, mapeamentoColunas['codigo']);
          final descricao = _obterCampo(row, mapeamentoColunas['descricao']) ?? 'Peça Automotiva';
          final marca = _obterCampo(row, mapeamentoColunas['marca']) ?? 'PARALELO';
          final montadora = _obterCampo(row, mapeamentoColunas['montadora']) ?? 'Multimarcas';
          final modelo = _obterCampo(row, mapeamentoColunas['modelo']) ?? 'Diversos';
          final anoStr = _obterCampo(row, mapeamentoColunas['ano']) ?? '2020';
          final motor = _obterCampo(row, mapeamentoColunas['motor']) ?? '1.0';
          final posicao = _obterCampo(row, mapeamentoColunas['posicao']) ?? 'Dianteiro';
          final codigoOem = _obterCampo(row, mapeamentoColunas['codigoOem']) ?? '';

          if (codigo == null || codigo.trim().isEmpty) {
            erros++;
            logErros.add('Linha $linhaNumero: Código da peça está em branco.');
            continue;
          }

          final ano = int.tryParse(anoStr) ?? 2020;

          // Verifica duplicidade no banco existente
          final jaExiste = _db.conversoes.any((c) {
            final mesmoModelo = c.veiculo.modelo.toLowerCase() == modelo.toLowerCase();
            final mesmoCodigo = c.equivalentes.any((eq) => eq.codigo.toUpperCase() == codigo.toUpperCase());
            return mesmoModelo && mesmoCodigo;
          });

          if (jaExiste) {
            duplicados++;
            atualizados++;
          } else {
            novos++;
          }

          previaRegistros.add({
            'linha': linhaNumero,
            'codigo': codigo,
            'descricao': descricao,
            'marca': marca,
            'montadora': montadora,
            'modelo': modelo,
            'ano': ano,
            'motor': motor,
            'posicao': posicao,
            'codigoOem': codigoOem,
            'status': jaExiste ? 'Duplicado (Existente)' : 'Novo',
          });
        } catch (e) {
          erros++;
          logErros.add('Linha $linhaNumero: Erro ao interpretar colunas ($e)');
        }
      }

      return ImportResultModel(
        totalLinhas: dataRows.length,
        registrosNovos: novos,
        registrosAtualizados: atualizados,
        registrosDuplicados: duplicados,
        registrosComErro: erros,
        logErros: logErros,
        registrosPrevia: previaRegistros,
      );
    } catch (e) {
      return ImportResultModel(
        totalLinhas: 0,
        registrosNovos: 0,
        registrosAtualizados: 0,
        registrosDuplicados: 0,
        registrosComErro: 1,
        logErros: ['Falha ao processar arquivo: $e'],
      );
    }
  }

  String? _obterCampo(List row, int? index) {
    if (index == null || index < 0 || index >= row.length) return null;
    final val = row[index]?.toString().trim();
    return (val != null && val.isNotEmpty) ? val : null;
  }

  /// Executa a inserção em lote dos registros validados no banco de dados.
  Future<int> executarImportacao({
    required List<Map<String, dynamic>> registrosPrevia,
    required DuplicidadeEstrategia estrategia,
    required String usuarioNome,
  }) async {
    int totalInseridos = 0;
    final now = DateTime.now();

    for (final reg in registrosPrevia) {
      final isDuplicado = reg['status'] == 'Duplicado (Existente)';

      if (isDuplicado && estrategia == DuplicidadeEstrategia.ignorar) {
        continue;
      }

      final veiculo = VeiculoModel(
        id: 'v_imp_${DateTime.now().millisecondsSinceEpoch}_$totalInseridos',
        montadora: reg['montadora'],
        modelo: reg['modelo'],
        versao: 'Todas as Versões',
        anoInicio: reg['ano'] - 2,
        anoFim: reg['ano'] + 2,
        motor: reg['motor'],
        combustivel: 'Flex',
        cilindrada: '',
      );

      final peca = PecaModel(
        id: 'p_imp_${DateTime.now().millisecondsSinceEpoch}_$totalInseridos',
        descricao: reg['descricao'],
        categoria: CategoriaPeca.suspensao,
        codigoOem: reg['codigoOem'] ?? '',
        montadoraOrigem: reg['montadora'],
        posicao: reg['posicao'],
      );

      final conversao = ConversaoModel(
        id: 'conv_imp_${DateTime.now().millisecondsSinceEpoch}_$totalInseridos',
        peca: peca,
        veiculo: veiculo,
        equivalentes: [
          CodigoEquivalenteItem(
            fabricanteNome: reg['marca'],
            codigo: reg['codigo'],
            descricaoEspecifica: reg['descricao'],
          ),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Importado via planilha de catálogo de fornecedor.',
        usuarioAtualizacao: usuarioNome,
        dataAtualizacao: now,
      );

      await _db.addConversao(conversao);
      totalInseridos++;
    }

    _audit.registrarAcao(
      usuarioNome: usuarioNome,
      acao: 'IMPORTAÇÃO PLANILHA',
      entidade: 'Catálogo de Peças',
      descricao: 'Importados com sucesso $totalInseridos registros de catálogo.',
    );

    return totalInseridos;
  }
}
