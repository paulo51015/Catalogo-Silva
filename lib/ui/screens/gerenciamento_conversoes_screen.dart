import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../models/fabricante_model.dart';
import '../../models/peca_model.dart';
import '../../models/veiculo_model.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class GerenciamentoConversoesScreen extends StatefulWidget {
  final DatabaseService db;
  final AuditService audit;
  final AuthService auth;

  const GerenciamentoConversoesScreen({
    super.key,
    required this.db,
    required this.audit,
    required this.auth,
  });

  @override
  State<GerenciamentoConversoesScreen> createState() => _GerenciamentoConversoesScreenState();
}

class _GerenciamentoConversoesScreenState extends State<GerenciamentoConversoesScreen> {
  void _abrirModalNovaConversao([ConversaoModel? edicao]) {
    final bool isEdit = edicao != null;

    VeiculoModel? veiculoSelecionado = isEdit ? edicao.veiculo : (widget.db.veiculos.isNotEmpty ? widget.db.veiculos.first : null);
    CategoriaPeca categoriaSelecionada = isEdit ? edicao.peca.categoria : CategoriaPeca.suspensao;
    StatusConfiabilidade statusSelecionado = isEdit ? edicao.status : StatusConfiabilidade.confirmada;
    FonteConversao fonteSelecionada = isEdit ? edicao.fonte : FonteConversao.catalogoFabricante;

    final descricaoController = TextEditingController(text: isEdit ? edicao.peca.descricao : 'Amortecedor Dianteiro');
    final oemController = TextEditingController(text: isEdit ? edicao.peca.codigoOem : '');
    final posicaoController = TextEditingController(text: isEdit ? edicao.peca.posicao : 'Dianteiro');
    final obsController = TextEditingController(text: isEdit ? edicao.observacaoCompatibilidade : '');

    // Lista de equivalentes
    final List<CodigoEquivalenteItem> equivalentes = isEdit
        ? List.from(edicao.equivalentes)
        : [
            const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: ''),
            const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: ''),
          ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: Text(
                isEdit ? 'Editar Conversão' : 'Nova Conversão Homologada',
                style: const TextStyle(color: AppTheme.silvaGold, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Veículo
                      DropdownButtonFormField<VeiculoModel>(
                        value: veiculoSelecionado,
                        decoration: const InputDecoration(labelText: 'Veículo de Aplicação'),
                        items: widget.db.veiculos.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text(
                              '${v.montadora} ${v.modelo} (${v.periodoAno})',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setModalState(() => veiculoSelecionado = v),
                      ),
                      const SizedBox(height: 12),

                      // 2. Peça & Categoria
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: descricaoController,
                              decoration: const InputDecoration(labelText: 'Descrição da Peça'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<CategoriaPeca>(
                              value: categoriaSelecionada,
                              decoration: const InputDecoration(labelText: 'Categoria'),
                              items: CategoriaPeca.values.map((c) {
                                return DropdownMenuItem(value: c, child: Text('${c.icone} ${c.nomeExibicao}', style: const TextStyle(fontSize: 12)));
                              }).toList>,
                              onChanged: (c) => setModalState(() => categoriaSelecionada = c!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. OEM & Posição
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: oemController,
                              decoration: const InputDecoration(labelText: 'Código OEM Original (Montadora)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: posicaoController,
                              decoration: const InputDecoration(labelText: 'Posição (Dianteiro/Traseiro)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Códigos Equivalentes por Marca
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Marcas Equivalentes (Paralelas):',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.silvaCyan, fontSize: 13),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                equivalentes.add(const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: ''));
                              });
                            },
                            icon: const Icon(Icons.add, size: 16, color: AppTheme.silvaGold),
                            label: const Text('Adicionar Marca', style: TextStyle(color: AppTheme.silvaGold, fontSize: 12)),
                          ),
                        ],
                      ),
                      ...equivalentes.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: item.fabricanteNome,
                                  decoration: const InputDecoration(labelText: 'Marca (ex: COFAP)'),
                                  onChanged: (val) {
                                    equivalentes[idx] = CodigoEquivalenteItem(
                                      fabricanteNome: val,
                                      codigo: equivalentes[idx].codigo,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: item.codigo,
                                  decoration: const InputDecoration(labelText: 'Código da Peça'),
                                  onChanged: (val) {
                                    equivalentes[idx] = CodigoEquivalenteItem(
                                      fabricanteNome: equivalentes[idx].fabricanteNome,
                                      codigo: val,
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed, size: 20),
                                onPressed: () {
                                  setModalState(() {
                                    equivalentes.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      // 5. Status & Fonte
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<StatusConfiabilidade>(
                              value: statusSelecionado,
                              decoration: const InputDecoration(labelText: 'Confiabilidade'),
                              items: StatusConfiabilidade.values.map((s) {
                                return DropdownMenuItem(value: s, child: Text('${s.icone} ${s.nomeExibicao}', style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (s) => setModalState(() => statusSelecionado = s!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<FonteConversao>(
                              value: fonteSelecionada,
                              decoration: const InputDecoration(labelText: 'Fonte da Informação'),
                              items: FonteConversao.values.map((f) {
                                return DropdownMenuItem(value: f, child: Text(f.nomeExibicao, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (f) => setModalState(() => fonteSelecionada = f!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: obsController,
                        decoration: const InputDecoration(labelText: 'Observações de Compatibilidade Técnica'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (veiculoSelecionado == null || descricaoController.text.trim().isEmpty) return;

                    final peca = PecaModel(
                      id: isEdit ? edicao.peca.id : 'p_${DateTime.now().millisecondsSinceEpoch}',
                      descricao: descricaoController.text.trim(),
                      categoria: categoriaSelecionada,
                      codigoOem: oemController.text.trim(),
                      montadoraOrigem: veiculoSelecionado!.montadora,
                      posicao: posicaoController.text.trim(),
                    );

                    final conversao = ConversaoModel(
                      id: isEdit ? edicao.id : 'conv_${DateTime.now().millisecondsSinceEpoch}',
                      peca: peca,
                      veiculo: veiculoSelecionado!,
                      equivalentes: equivalentes.where((e) => e.codigo.trim().isNotEmpty).toList(),
                      status: statusSelecionado,
                      fonte: fonteSelecionada,
                      observacaoCompatibilidade: obsController.text.trim(),
                      usuarioAtualizacao: widget.auth.currentUser?.nome ?? 'Administrador',
                      dataAtualizacao: DateTime.now(),
                    );

                    if (isEdit) {
                      widget.db.updateConversao(conversao);
                      widget.audit.registrarAcao(
                        usuarioNome: widget.auth.currentUser?.nome ?? 'Admin',
                        acao: 'EDIÇÃO',
                        entidade: 'Conversão',
                        descricao: 'Atualizada conversão para ${veiculoSelecionado!.nomeCompleto} - ${peca.descricao}',
                      );
                    } else {
                      widget.db.addConversao(conversao);
                      widget.audit.registrarAcao(
                        usuarioNome: widget.auth.currentUser?.nome ?? 'Admin',
                        acao: 'INSERÇÃO',
                        entidade: 'Conversão',
                        descricao: 'Cadastrada nova conversão para ${veiculoSelecionado!.nomeCompleto} - ${peca.descricao}',
                      );
                    }

                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text(isEdit ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR CONVERSÃO'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.db.conversoes;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Gestão de Conversões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.silvaGold, size: 28),
            onPressed: () => _abrirModalNovaConversao(),
            tooltip: 'Cadastrar Nova Conversão',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.silvaGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('NOVA CONVERSÃO', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _abrirModalNovaConversao(),
      ),
      body: list.isEmpty
          ? const Center(child: Text('Nenhuma conversão cadastrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final c = list[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceLight,
                      child: Text(c.peca.categoria.icone, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(
                      '${c.veiculo.montadora} ${c.veiculo.modelo} — ${c.peca.descricao}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('OEM: ${c.peca.codigoOem} • Anos: ${c.veiculo.periodoAno}', style: const TextStyle(fontSize: 12, color: AppTheme.silvaCyan)),
                        const SizedBox(height: 2),
                        Text(
                          'Marcas: ${c.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').join(' | ')}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.silvaCyan, size: 20),
                          onPressed: () => _abrirModalNovaConversao(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.errorRed, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir Conversão?'),
                                content: Text('Deseja excluir a conversão de ${c.peca.descricao} do veículo ${c.veiculo.modelo}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                                  ElevatedButton(
                                    onPressed: () {
                                      widget.db.deleteConversao(c.id);
                                      widget.audit.registrarAcao(
                                        usuarioNome: widget.auth.currentUser?.nome ?? 'Admin',
                                        acao: 'EXCLUSÃO',
                                        entidade: 'Conversão',
                                        descricao: 'Excluída conversão de ${c.peca.descricao} do ${c.veiculo.modelo}',
                                      );
                                      Navigator.pop(ctx);
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                                    child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
