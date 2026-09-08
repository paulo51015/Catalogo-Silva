import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../models/peca_model.dart';
import '../../services/database_service.dart';
import '../../services/search_engine_service.dart';
import '../../theme/app_theme.dart';

class FiltroBalcaoModal extends StatefulWidget {
  final DatabaseService db;
  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onApplyFilters;

  const FiltroBalcaoModal({
    super.key,
    required this.db,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<FiltroBalcaoModal> createState() => _FiltroBalcaoModalState();
}

class _FiltroBalcaoModalState extends State<FiltroBalcaoModal> {
  String? _montadora;
  String? _modelo;
  int? _ano;
  CategoriaPeca? _categoria;
  String? _posicao;
  String? _fabricanteParalelo;
  StatusConfiabilidade? _status;

  final TextEditingController _anoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _montadora = widget.initialFilters.montadora;
    _modelo = widget.initialFilters.modelo;
    _ano = widget.initialFilters.ano;
    _categoria = widget.initialFilters.categoria;
    _posicao = widget.initialFilters.posicao;
    _fabricanteParalelo = widget.initialFilters.fabricanteParalelo;
    _status = widget.initialFilters.status;

    if (_ano != null) {
      _anoController.text = _ano.toString();
    }
  }

  @override
  void dispose() {
    _anoController.dispose();
    super.dispose();
  }

  void _limparFiltros() {
    setState(() {
      _montadora = null;
      _modelo = null;
      _ano = null;
      _categoria = null;
      _posicao = null;
      _fabricanteParalelo = null;
      _status = null;
      _anoController.clear();
    });
  }

  void _aplicar() {
    final parsedAno = int.tryParse(_anoController.text.trim());
    final filters = SearchFilters(
      montadora: _montadora,
      modelo: _modelo,
      ano: parsedAno,
      categoria: _categoria,
      posicao: _posicao,
      fabricanteParalelo: _fabricanteParalelo,
      status: _status,
    );
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final montadoras = widget.db.veiculos.map((v) => v.montadora).toSet().toList()..sort();
    final marcas = widget.db.fabricantes.map((f) => f.nome).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_alt, color: AppTheme.silvaGold),
                    SizedBox(width: 8),
                    Text(
                      'Filtros de Balcão',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _limparFiltros,
                  child: const Text('Limpar Todos', style: TextStyle(color: AppTheme.silvaCyan)),
                ),
              ],
            ),
            const Divider(color: AppTheme.dividerColor),
            const SizedBox(height: 10),

            // 1. Montadora
            DropdownButtonFormField<String>(
              value: _montadora,
              decoration: const InputDecoration(labelText: 'Montadora do Veículo', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              hint: const Text('Todas as Montadoras'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas as Montadoras')),
                ...montadoras.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (v) => setState(() => _montadora = v),
            ),
            const SizedBox(height: 12),

            // 2. Ano & Categoria
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _anoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ano do Carro',
                      hintText: 'Ex: 2020',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<CategoriaPeca>(
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria da Peça', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    hint: const Text('Todas'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas as Categorias')),
                      ...CategoriaPeca.values.map(
                        (c) => DropdownMenuItem(value: c, child: Text('${c.icone} ${c.nomeExibicao}', style: const TextStyle(fontSize: 13))),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoria = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Fabricante Paralelo
            DropdownButtonFormField<String>(
              value: _fabricanteParalelo,
              decoration: const InputDecoration(labelText: 'Fabricante da Peça (Marca Paralela)', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              hint: const Text('Todas as Marcas (COFAP, Monroe, etc.)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas as Marcas')),
                ...marcas.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (v) => setState(() => _fabricanteParalelo = v),
            ),
            const SizedBox(height: 12),

            // 4. Status de Confiabilidade
            DropdownButtonFormField<StatusConfiabilidade>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status de Confiabilidade', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              hint: const Text('Todos os Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos os Status')),
                ...StatusConfiabilidade.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text('${s.icone} ${s.nomeExibicao}')),
                ),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 20),

            // Botão Aplicar
            ElevatedButton(
              onPressed: _aplicar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.silvaGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'APLICAR FILTROS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
