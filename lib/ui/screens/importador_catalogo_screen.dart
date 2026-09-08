import 'package:flutter/material.dart';
import '../../models/import_result_model.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/import_service.dart';
import '../../theme/app_theme.dart';

class ImportadorCatalogoScreen extends StatefulWidget {
  final DatabaseService db;
  final AuditService audit;
  final AuthService auth;

  const ImportadorCatalogoScreen({
    super.key,
    required this.db,
    required this.audit,
    required this.auth,
  });

  @override
  State<ImportadorCatalogoScreen> createState() => _ImportadorCatalogoScreenState();
}

class _ImportadorCatalogoScreenState extends State<ImportadorCatalogoScreen> {
  late ImportService _importService;
  final TextEditingController _csvContentController = TextEditingController();

  DuplicidadeEstrategia _estrategia = DuplicidadeEstrategia.atualizar;
  ImportResultModel? _resultadoAnalise;
  bool _isProcessing = false;

  // Mapeamento padrão de colunas (índices 0 a 8)
  final Map<String, int> _mapeamento = {
    'codigo': 0,
    'descricao': 1,
    'marca': 2,
    'montadora': 3,
    'modelo': 4,
    'ano': 5,
    'motor': 6,
    'posicao': 7,
    'codigoOem': 8,
  };

  // Exemplo de planilha de fornecedor pronta para teste
  final String _exemploPlanilhaCsv = '''Codigo,Descricao,Marca,Montadora,Modelo,Ano,Motor,Posicao,CodigoOEM
GP33256,Amortecedor Dianteiro Turbogás,COFAP,Toyota,Corolla,2021,2.0,Dianteiro,48510-02880
742084SP,Amortecedor OESpectrum,MONROE,Toyota,Corolla,2022,2.0,Dianteiro,48510-02880
HG31145,Amortecedor Dianteiro Pressurizado,NAKATA,Volkswagen,Gol,2018,1.6,Dianteiro,5U0413031
PD/1544,Jogo de Pastilha Cerâmica,FRAS-LE,Toyota,Corolla,2023,2.0,Dianteiro,04465-02400
0986BB0230,Jogo de Pastilha Dianteira,BOSCH,Volkswagen,Gol,2019,1.6,Dianteiro,5Z0698151A
GP33342,Amortecedor Dianteiro Turbogás,COFAP,Chevrolet,Onix,2022,1.0 Turbo,Dianteiro,26245362
3330058,Amortecedor Dianteiro Excel-G,KYB,Hyundai,HB20,2023,1.0,Dianteiro,54650-1S000
SP038,Amortecedor Dianteiro Monro-Matic,MONROE,Volkswagen,Polo,2020,1.0 TSI,Dianteiro,6R0413031''';

  @override
  void initState() {
    super.initState();
    _importService = ImportService(widget.db, widget.audit);
    _csvContentController.text = _exemploPlanilhaCsv;
    _analisarConteudo();
  }

  @override
  void dispose() {
    _csvContentController.dispose();
    super.dispose();
  }

  void _analisarConteudo() {
    final raw = _csvContentController.text.trim();
    if (raw.isEmpty) {
      setState(() => _resultadoAnalise = null);
      return;
    }

    final analise = _importService.analisarPlanilha(
      rawContent: raw,
      mapeamentoColunas: _mapeamento,
    );

    setState(() {
      _resultadoAnalise = analise;
    });
  }

  Future<void> _executarImportacao() async {
    if (_resultadoAnalise == null || _resultadoAnalise!.registrosPrevia.isEmpty) return;

    setState(() => _isProcessing = true);

    final usuarioNome = widget.auth.currentUser?.nome ?? 'Administrador';
    final totalInseridos = await _importService.executarImportacao(
      registrosPrevia: _resultadoAnalise!.registrosPrevia,
      estrategia: _estrategia,
      usuarioNome: usuarioNome,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen),
              SizedBox(width: 8),
              Text('Importação Concluída'),
            ],
          ),
          content: Text(
            'Foram importados/atualizados com sucesso $totalInseridos registros no catálogo do Centro Automotivo Silva sem apagar a base existente.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _analisarConteudo();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Importador de Catálogos (Excel / CSV)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header explicativo
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.silvaGold.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.upload_file, color: AppTheme.silvaGold, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Importe tabelas de fabricantes e distribuidores (.xlsx ou .csv). O sistema valida as colunas, identifica duplicidades e nunca apaga sua base existente.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Área de Entrada de Dados / Planilha
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Conteúdo da Planilha (CSV / Dados)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.silvaGold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _csvContentController.text = _exemploPlanilhaCsv;
                            _analisarConteudo();
                          },
                          icon: const Icon(Icons.file_copy, size: 16, color: AppTheme.silvaCyan),
                          label: const Text('Carregar Modelo Exemplo', style: TextStyle(color: AppTheme.silvaCyan, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _csvContentController,
                      maxLines: 5,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Cole aqui o conteúdo CSV da planilha do fornecedor...',
                      ),
                      onChanged: (_) => _analisarConteudo(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Painel de Estatísticas da Prévia
            if (_resultadoAnalise != null) ...[
              const Text(
                'Validação e Estatísticas Pré-Importação:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCard('Total Linhas', '${_resultadoAnalise!.totalLinhas}', AppTheme.silvaCyan),
                  const SizedBox(width: 8),
                  _buildStatCard('Novos', '${_resultadoAnalise!.registrosNovos}', AppTheme.successGreen),
                  const SizedBox(width: 8),
                  _buildStatCard('Duplicados', '${_resultadoAnalise!.registrosDuplicados}', AppTheme.warningAmber),
                  const SizedBox(width: 8),
                  _buildStatCard('Erros', '${_resultadoAnalise!.registrosComErro}', AppTheme.errorRed),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Tratamento de Duplicidades
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ação para Códigos Duplicados / Já Existentes:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.silvaGold),
                      ),
                      const SizedBox(height: 6),
                      RadioListTile<DuplicidadeEstrategia>(
                        value: DuplicidadeEstrategia.atualizar,
                        groupValue: _estrategia,
                        title: const Text('Atualizar registros existentes com os novos dados', style: TextStyle(fontSize: 13)),
                        activeColor: AppTheme.silvaGold,
                        dense: true,
                        onChanged: (v) => setState(() => _estrategia = v!),
                      ),
                      RadioListTile<DuplicidadeEstrategia>(
                        value: DuplicidadeEstrategia.ignorar,
                        groupValue: _estrategia,
                        title: const Text('Ignorar duplicados (manter base atual inalterada)', style: TextStyle(fontSize: 13)),
                        activeColor: AppTheme.silvaGold,
                        dense: true,
                        onChanged: (v) => setState(() => _estrategia = v!),
                      ),
                      RadioListTile<DuplicidadeEstrategia>(
                        value: DuplicidadeEstrategia.criarNovo,
                        groupValue: _estrategia,
                        title: const Text('Criar novos registros adicionais', style: TextStyle(fontSize: 13)),
                        activeColor: AppTheme.silvaGold,
                        dense: true,
                        onChanged: (v) => setState(() => _estrategia = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Tabela de Prévia dos Registros
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prévia dos Registros a Importar:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                      const Divider(color: AppTheme.dividerColor),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          itemCount: _resultadoAnalise!.registrosPrevia.length,
                          separatorBuilder: (_, __) => const Divider(color: AppTheme.dividerColor, height: 1),
                          itemBuilder: (context, index) {
                            final item = _resultadoAnalise!.registrosPrevia[index];
                            final isDup = item['status'] == 'Duplicado (Existente)';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDup ? AppTheme.warningAmber.withOpacity(0.2) : AppTheme.successGreen.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isDup ? 'EXISTENTE' : 'NOVO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDup ? AppTheme.warningAmber : AppTheme.successGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${item['marca']} ${item['codigo']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${item['montadora']} ${item['modelo']} (${item['ano']})',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.silvaCyan),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${item['descricao']} - ${item['posicao']}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 6. Botão de Execução
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _executarImportacao,
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.cloud_upload, color: Colors.black),
                label: Text(
                  _isProcessing ? 'IMPORTANDO DADOS...' : 'EXECUTAR IMPORTAÇÃO EM LOTE',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.silvaGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
