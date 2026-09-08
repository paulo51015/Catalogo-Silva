import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/historico_busca_model.dart';

/// Serviço que gerencia o histórico de buscas dos colaboradores no balcão.
class HistoryService extends ChangeNotifier {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final List<HistoricoBuscaModel> _historico = [];
  List<HistoricoBuscaModel> get historico => List.unmodifiable(_historico);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getString('silva_search_history');
    if (savedHistory != null) {
      final List list = jsonDecode(savedHistory);
      _historico.clear();
      _historico.addAll(list.map((m) => HistoricoBuscaModel.fromMap(m)));
    } else {
      // Exemplos iniciais
      _historico.addAll([
        HistoricoBuscaModel(
          id: 'hist_1',
          usuarioId: 'usr_balcao',
          termoPesquisa: 'Corolla 2020 amortecedor',
          totalResultados: 2,
          dataHora: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        HistoricoBuscaModel(
          id: 'hist_2',
          usuarioId: 'usr_balcao',
          termoPesquisa: 'Gol pastilha',
          totalResultados: 1,
          dataHora: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        HistoricoBuscaModel(
          id: 'hist_3',
          usuarioId: 'usr_balcao',
          termoPesquisa: 'Onix',
          totalResultados: 2,
          dataHora: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ]);
    }
    notifyListeners();
  }

  Future<void> registrarBusca({
    required String usuarioId,
    required String termo,
    required int totalResultados,
  }) async {
    final cleanTermo = termo.trim();
    if (cleanTermo.isEmpty) return;

    // Remove duplicatas recentes do mesmo termo
    _historico.removeWhere((h) => h.termoPesquisa.toLowerCase() == cleanTermo.toLowerCase());

    final item = HistoricoBuscaModel(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
      usuarioId: usuarioId,
      termoPesquisa: cleanTermo,
      totalResultados: totalResultados,
      dataHora: DateTime.now(),
    );

    _historico.insert(0, item);
    if (_historico.length > 30) {
      _historico.removeLast();
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('silva_search_history', jsonEncode(_historico.map((h) => h.toMap()).toList()));
    } catch (e) {
      debugPrint('Erro ao salvar histórico de busca: $e');
    }
  }

  Future<void> limparHistorico() async {
    _historico.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('silva_search_history');
    notifyListeners();
  }
}
