import '../models/conversao_model.dart';
import '../models/peca_model.dart';
import 'database_service.dart';

class SearchFilters {
  final String? montadora;
  final String? modelo;
  final int? ano;
  final CategoriaPeca? categoria;
  final String? posicao;
  final String? fabricanteParalelo;
  final StatusConfiabilidade? status;

  const SearchFilters({
    this.montadora,
    this.modelo,
    this.ano,
    this.categoria,
    this.posicao,
    this.fabricanteParalelo,
    this.status,
  });

  bool get isEmpty =>
      montadora == null &&
      modelo == null &&
      ano == null &&
      categoria == null &&
      posicao == null &&
      fabricanteParalelo == null &&
      status == null;
}

/// Motor de Busca Inteligente de Peças e Conversões do Centro Automotivo Silva.
class SearchEngineService {
  final DatabaseService _db;

  SearchEngineService(this._db);

  /// Normaliza códigos removendo pontuação, barras e espaços para busca exata e parcial.
  static String normalizeCode(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Executa busca rápida de balcão por query textual e filtros combinados.
  List<ConversaoModel> search({
    required String query,
    SearchFilters filters = const SearchFilters(),
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final normalizedCodeQuery = normalizeCode(query);

    final allConversoes = _db.conversoes;

    if (cleanQuery.isEmpty && filters.isEmpty) {
      return allConversoes;
    }

    final queryTokens = cleanQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    final results = allConversoes.where((conversao) {
      // 1. Aplicação de Filtros Específicos
      if (filters.montadora != null && filters.montadora!.isNotEmpty) {
        if (conversao.veiculo.montadora.toLowerCase() != filters.montadora!.toLowerCase()) {
          return false;
        }
      }

      if (filters.modelo != null && filters.modelo!.isNotEmpty) {
        if (!conversao.veiculo.modelo.toLowerCase().contains(filters.modelo!.toLowerCase())) {
          return false;
        }
      }

      if (filters.ano != null) {
        if (!conversao.veiculo.compativelComAno(filters.ano!)) {
          return false;
        }
      }

      if (filters.categoria != null) {
        if (conversao.peca.categoria != filters.categoria) {
          return false;
        }
      }

      if (filters.posicao != null && filters.posicao!.isNotEmpty) {
        if (!conversao.peca.posicao.toLowerCase().contains(filters.posicao!.toLowerCase())) {
          return false;
        }
      }

      if (filters.status != null) {
        if (conversao.status != filters.status) {
          return false;
        }
      }

      if (filters.fabricanteParalelo != null && filters.fabricanteParalelo!.isNotEmpty) {
        final hasBrand = conversao.equivalentes.any(
          (eq) => eq.fabricanteNome.toLowerCase() == filters.fabricanteParalelo!.toLowerCase(),
        );
        if (!hasBrand) return false;
      }

      // Se não houver texto de busca além dos filtros, passa direto
      if (cleanQuery.isEmpty) return true;

      // 2. Busca por Código (OEM ou Paralelo) - Normalizado & Substring
      if (normalizedCodeQuery.isNotEmpty) {
        // Código OEM
        final oemNorm = normalizeCode(conversao.peca.codigoOem);
        if (oemNorm.contains(normalizedCodeQuery)) return true;

        // Códigos de Fabricantes Equivalentes (COFAP, Monroe, Nakata, etc.)
        for (final eq in conversao.equivalentes) {
          final eqNorm = normalizeCode(eq.codigo);
          if (eqNorm.contains(normalizedCodeQuery)) return true;
        }
      }

      // 3. Busca Textual por Tokens (ex: "Corolla 2020 amortecedor")
      final fullTextCorpus = [
        conversao.veiculo.montadora,
        conversao.veiculo.modelo,
        conversao.veiculo.versao,
        conversao.veiculo.motor,
        conversao.veiculo.combustivel,
        '${conversao.veiculo.anoInicio}',
        '${conversao.veiculo.anoFim}',
        conversao.peca.descricao,
        conversao.peca.categoria.nomeExibicao,
        conversao.peca.codigoOem,
        conversao.peca.posicao,
        conversao.peca.eixo,
        conversao.peca.lado,
        conversao.observacaoCompatibilidade,
        ...conversao.equivalentes.map((e) => '${e.fabricanteNome} ${e.codigo} ${e.linha ?? ''}'),
      ].join(' ').toLowerCase();

      // Verifica se TODOS os tokens digitados estão presentes no registro
      final bool matchesAllTokens = queryTokens.every((token) {
        // Se o token for um número de ano (ex: 2020), valida o intervalo do veículo
        final parsedYear = int.tryParse(token);
        if (parsedYear != null && parsedYear >= 1970 && parsedYear <= 2030) {
          if (conversao.veiculo.compativelComAno(parsedYear)) return true;
        }

        // Caso contrário, busca como substring normal
        return fullTextCorpus.contains(token);
      });

      return matchesAllTokens;
    }).toList();

    return results;
  }
}
