import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/conversao_model.dart';
import '../../models/peca_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/history_service.dart';
import '../../services/search_engine_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/conversao_card_widget.dart';
import '../widgets/filtro_balcao_widget.dart';
import '../widgets/header_silva_widget.dart';
import 'conversao_detail_screen.dart';

class BalcaoSearchScreen extends StatefulWidget {
  final DatabaseService db;
  final AuthService auth;
  final HistoryService history;

  const BalcaoSearchScreen({
    super.key,
    required this.db,
    required this.auth,
    required this.history,
  });

  @override
  State<BalcaoSearchScreen> createState() => _BalcaoSearchScreenState();
}

class _BalcaoSearchScreenState extends State<BalcaoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late SearchEngineService _searchEngine;

  SearchFilters _activeFilters = const SearchFilters();
  List<ConversaoModel> _searchResults = [];

  final List<String> _sugestoesRapidas = [
    'Corolla 2020 amortecedor',
    'Gol pastilha de freio',
    'Onix amortecedor',
    'Strada 1.3',
    'HB20 amortecedor',
    'GP33256',
    '3392',
  ];

  @override
  void initState() {
    super.initState();
    _searchEngine = SearchEngineService(widget.db);
    _executarBusca();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _executarBusca([String? query]) {
    final q = query ?? _searchController.text;
    final results = _searchEngine.search(
      query: q,
      filters: _activeFilters,
    );

    setState(() {
      _searchResults = results;
    });

    if (q.trim().isNotEmpty && widget.auth.currentUser != null) {
      widget.history.registrarBusca(
        usuarioId: widget.auth.currentUser!.id,
        termo: q,
        totalResultados: results.length,
      );
    }
  }

  void _abrirModalFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltroBalcaoModal(
        db: widget.db,
        initialFilters: _activeFilters,
        onApplyFilters: (newFilters) {
          setState(() {
            _activeFilters = newFilters;
          });
          _executarBusca();
        },
      ),
    );
  }

  void _limparFiltroItem(String tipo) {
    setState(() {
      switch (tipo) {
        case 'montadora':
          _activeFilters = SearchFilters(
            modelo: _activeFilters.modelo,
            ano: _activeFilters.ano,
            categoria: _activeFilters.categoria,
            posicao: _activeFilters.posicao,
            fabricanteParalelo: _activeFilters.fabricanteParalelo,
            status: _activeFilters.status,
          );
          break;
        case 'ano':
          _activeFilters = SearchFilters(
            montadora: _activeFilters.montadora,
            modelo: _activeFilters.modelo,
            categoria: _activeFilters.categoria,
            posicao: _activeFilters.posicao,
            fabricanteParalelo: _activeFilters.fabricanteParalelo,
            status: _activeFilters.status,
          );
          break;
        case 'categoria':
          _activeFilters = SearchFilters(
            montadora: _activeFilters.montadora,
            modelo: _activeFilters.modelo,
            ano: _activeFilters.ano,
            posicao: _activeFilters.posicao,
            fabricanteParalelo: _activeFilters.fabricanteParalelo,
            status: _activeFilters.status,
          );
          break;
        case 'fabricante':
          _activeFilters = SearchFilters(
            montadora: _activeFilters.montadora,
            modelo: _activeFilters.modelo,
            ano: _activeFilters.ano,
            categoria: _activeFilters.categoria,
            posicao: _activeFilters.posicao,
            status: _activeFilters.status,
          );
          break;
      }
    });
    _executarBusca();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header do Centro Automotivo Silva
              HeaderSilvaWidget(db: widget.db, auth: widget.auth),
              const SizedBox(height: 12),

              // 2. Grande Barra de Pesquisa de Balcão
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.silvaGold, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (text) => _executarBusca(text),
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Digite código (ex: 3392, GP33256), veículo ou peça...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.silvaGold, size: 26),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _executarBusca('');
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: _activeFilters.isEmpty ? AppTheme.silvaCyan : AppTheme.silvaGold,
                          ),
                          onPressed: _abrirModalFiltros,
                          tooltip: 'Filtros avançados',
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Atalhos de Sugestões Rápidas
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sugestoesRapidas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final sug = _sugestoesRapidas[index];
                    return ActionChip(
                      label: Text(sug, style: const TextStyle(fontSize: 11, color: AppTheme.silvaCyan)),
                      backgroundColor: AppTheme.surfaceLight,
                      side: const BorderSide(color: AppTheme.dividerColor),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: () {
                        _searchController.text = sug;
                        _executarBusca(sug);
                      },
                    );
                  },
                ),
              ),

              // 4. Badges de Filtros Ativos (se houver)
              if (!_activeFilters.isEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    if (_activeFilters.montadora != null)
                      Chip(
                        label: Text('Montadora: ${_activeFilters.montadora}'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _limparFiltroItem('montadora'),
                      ),
                    if (_activeFilters.ano != null)
                      Chip(
                        label: Text('Ano: ${_activeFilters.ano}'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _limparFiltroItem('ano'),
                      ),
                    if (_activeFilters.categoria != null)
                      Chip(
                        label: Text('Cat: ${_activeFilters.categoria!.nomeExibicao}'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _limparFiltroItem('categoria'),
                      ),
                    if (_activeFilters.fabricanteParalelo != null)
                      Chip(
                        label: Text('Marca: ${_activeFilters.fabricanteParalelo}'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _limparFiltroItem('fabricante'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // 5. Barra de Estatística de Resultados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resultados Encontrados (${_searchResults.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty || !_activeFilters.isEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _activeFilters = const SearchFilters();
                        _executarBusca('');
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Limpar Busca', style: TextStyle(color: AppTheme.silvaGold, fontSize: 12)),
                    ),
                ],
              ),
              const Divider(color: AppTheme.dividerColor),

              // 6. Lista de Resultados / Conversões
              Expanded(
                child: _searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final conv = _searchResults[index];
                          return ConversaoCardWidget(
                            conversao: conv,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConversaoDetailScreen(conversao: conv),
                                ),
                              );
                            },
                            onToggleFavorito: () {
                              widget.db.toggleFavorito(conv.id);
                              _executarBusca();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 54, color: AppTheme.warningAmber),
            const SizedBox(height: 16),
            const Text(
              'Não encontrada conversão cadastrada para esta aplicação.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'O sistema do Centro Automotivo Silva só apresenta equivalências homologadas. Nunca monte peças com base em semelhança visual ou códigos sem confirmação de catálogo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _activeFilters = const SearchFilters();
                _executarBusca('');
              },
              icon: const Icon(Icons.refresh, color: Colors.black, size: 18),
              label: const Text('VER TODO O CATÁLOGO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.silvaGold),
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }
}
