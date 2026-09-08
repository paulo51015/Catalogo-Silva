import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../services/database_service.dart';
import '../../services/vin_decoder_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/conversao_card_widget.dart';
import 'conversao_detail_screen.dart';

class ConsultaChassiScreen extends StatefulWidget {
  final DatabaseService db;

  const ConsultaChassiScreen({
    super.key,
    required this.db,
  });

  @override
  State<ConsultaChassiScreen> createState() => _ConsultaChassiScreenState();
}

class _ConsultaChassiScreenState extends State<ConsultaChassiScreen> {
  final TextEditingController _chassiController = TextEditingController();
  final VinDecoderService _vinService = VinDecoderService();

  VinDecodeResult? _resultadoDecode;
  List<ConversaoModel> _pecasCompativeis = [];

  final List<Map<String, String>> _chassisExemplo = [
    {'nome': 'Corolla 2021', 'vin': '9BRE4BBE7MP012345'},
    {'nome': 'Onix Turbo 2022', 'vin': '9BG1BONX4NG154321'},
    {'nome': 'Gol 1.6 2018', 'vin': '9BW5U5GOLJT987654'},
    {'nome': 'Strada 1.3 2021', 'vin': '9BD28STR1MB554433'},
    {'nome': 'HB20 2020', 'vin': '9BHB2HB20LP112233'},
    {'nome': 'Renegade 2021', 'vin': '98861REN5MP332211'},
    {'nome': 'Kwid 2020', 'vin': '93YB4KWI3LP667788'},
    {'nome': 'Civic G10 2019', 'vin': '93HFCIV14KS445566'},
    {'nome': 'Hilux 2.8 2021', 'vin': '8AJT1HIL8MP998877'},
  ];

  @override
  void dispose() {
    _chassiController.dispose();
    super.dispose();
  }

  void _consultarChassi([String? chassiInput]) {
    final query = chassiInput ?? _chassiController.text;
    final res = _vinService.decodificar(query);

    setState(() {
      _resultadoDecode = res;
      if (res.isValid) {
        final veiculosCompativeis = _vinService.encontrarVeiculosCompativeis(
          decode: res,
          veiculosDb: widget.db.veiculos,
        );

        final veiculoIds = veiculosCompativeis.map((v) => v.id).toSet();
        _pecasCompativeis = widget.db.conversoes.where((c) {
          return veiculoIds.contains(c.veiculo.id) ||
              c.veiculo.montadora.toLowerCase() == res.montadora.toLowerCase();
        }).toList();
      } else {
        _pecasCompativeis = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppTheme.silvaGold),
            SizedBox(width: 8),
            Text('Consulta por Número de Chassi (VIN)'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Informativo de Segurança Técnica
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.silvaGold.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppTheme.silvaGold, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Para peças com variações de lote, transição de ano ou motorizações complexas, informe o Chassi de 17 dígitos para garantir 100% de precisão.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Campo de Entrada do Chassi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Informe o Chassi do Veículo (17 caracteres alfanuméricos):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.silvaGold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chassiController,
                      maxLength: 17,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: 9BRE4BBE7MP012345',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary, letterSpacing: 1.5, fontSize: 14),
                        prefixIcon: const Icon(Icons.confirmation_number, color: AppTheme.silvaCyan),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: AppTheme.silvaGold),
                          onPressed: () => _consultarChassi(),
                        ),
                        counterText: '',
                      ),
                      onChanged: (text) {
                        if (text.length == 17) _consultarChassi(text);
                      },
                      onSubmitted: (text) => _consultarChassi(text),
                    ),
                    const SizedBox(height: 12),

                    // Botão de Decodificação
                    ElevatedButton.icon(
                      onPressed: () => _consultarChassi(),
                      icon: const Icon(Icons.search, color: Colors.black),
                      label: const Text('DECODIFICAR E VER PEÇAS EXATAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.silvaGold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Atalhos de Exemplos Rápidos de Chassis
            const Text(
              'Exemplos de Chassi para Teste Rápido no Balcão:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _chassisExemplo.map((ex) {
                return ActionChip(
                  backgroundColor: AppTheme.surfaceLight,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  label: Text('${ex['nome']} (${ex['vin']!.substring(0, 3)})', style: const TextStyle(fontSize: 11, color: AppTheme.silvaCyan)),
                  onPressed: () {
                    _chassiController.text = ex['vin']!;
                    _consultarChassi(ex['vin']);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. Painel de Resultado da Decodificação do Chassi
            if (_resultadoDecode != null) ...[
              if (!_resultadoDecode!.isValid) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _resultadoDecode!.mensagemErro ?? 'Chassi inválido.',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Card de Decomposição do Chassi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_resultadoDecode!.montadora} ${_resultadoDecode!.modeloSugerido} (${_resultadoDecode!.anoModelo})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.dividerColor),
                        const SizedBox(height: 6),

                        // Visualização das seções do VIN (WMI - VDS - VIS)
                        _buildVinSegmentView(_resultadoDecode!),
                        const SizedBox(height: 12),

                        _buildInfoLine('Montadora / Fabricante:', _resultadoDecode!.montadora),
                        _buildInfoLine('País / Unidade:', _resultadoDecode!.paisOrigem),
                        _buildInfoLine('Planta de Montagem:', _resultadoDecode!.plantaFabricacao),
                        _buildInfoLine('Ano-Modelo Identificado:', '${_resultadoDecode!.anoModelo ?? 'Não identificado'}'),
                        _buildInfoLine('Motorização Provável:', _resultadoDecode!.motorizacaoProvavel),
                        _buildInfoLine('Série de Produção:', _resultadoDecode!.numeroSerie),

                        if (_resultadoDecode!.alertasTecnicos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.warningAmber),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: AppTheme.warningAmber, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Atenção Técnica do Centro Automotivo Silva:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.warningAmber),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ..._resultadoDecode!.alertasTecnicos.map((alerta) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text('• $alerta', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de Peças Confirmadas para este Chassi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Peças Confirmadas por Chassi (${_pecasCompativeis.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.silvaGold),
                    ),
                    const Chip(
                      label: Text('Garantia 100% Chassi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_pecasCompativeis.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhuma conversão encontrada especificamente para este modelo.'),
                    ),
                  )
                else
                  ..._pecasCompativeis.map((conv) {
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
                        setState(() {});
                      },
                    );
                  }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVinSegmentView(VinDecodeResult r) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1622),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSegmentBlock('WMI (Origem)', r.wmi, AppTheme.silvaGold),
          const Text('•', style: TextStyle(color: AppTheme.textSecondary)),
          _buildSegmentBlock('VDS (Modelo)', r.vds, AppTheme.silvaCyan),
          const Text('•', style: TextStyle(color: AppTheme.textSecondary)),
          _buildSegmentBlock('Ano', r.vis.isNotEmpty ? r.vis.substring(0, 1) : '', AppTheme.successGreen),
          const Text('•', style: TextStyle(color: AppTheme.textSecondary)),
          _buildSegmentBlock('VIS (Série)', r.vis.length >= 2 ? r.vis.substring(1) : r.vis, Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSegmentBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
