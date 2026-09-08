import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/conversao_model.dart';
import '../../models/peca_model.dart';
import '../../theme/app_theme.dart';
import '../widgets/marca_badge_widget.dart';

class ConversaoDetailScreen extends StatelessWidget {
  final ConversaoModel conversao;

  const ConversaoDetailScreen({
    super.key,
    required this.conversao,
  });

  void _compartilharFichaTecnica() {
    final equivalentesStr = conversao.equivalentes
        .map((eq) => '• ${eq.fabricanteNome}: ${eq.codigo} ${eq.linha != null ? '(${eq.linha})' : ''}')
        .join('\n');

    final texto = '''
🔧 *CENTRO AUTOMOTIVO SILVA - CONSULTA DE PEÇAS*

🚗 *VEÍCULO*: ${conversao.veiculo.nomeCompleto}
⚙️ *PEÇA*: ${conversao.peca.descricao} (${conversao.peca.categoria.nomeExibicao})
📍 *POSIÇÃO*: ${conversao.peca.posicao} | Eixo: ${conversao.peca.eixo} | Lado: ${conversao.peca.lado}

🏷️ *CÓDIGO ORIGINAL (OEM ${conversao.peca.montadoraOrigem})*:
${conversao.peca.codigoOem.isNotEmpty ? conversao.peca.codigoOem : 'Não informado'}

📦 *CÓDIGOS EQUIVALENTES (MARCAS HOMOLOGADAS)*:
$equivalentesStr

✅ *STATUS*: ${conversao.status.nomeExibicao} (${conversao.fonte.nomeExibicao})
📝 *OBSERVAÇÃO*: ${conversao.observacaoCompatibilidade.isNotEmpty ? conversao.observacaoCompatibilidade : 'Nenhuma'}

Atendimento Centro Automotivo Silva
''';

    Share.share(texto, subject: 'Ficha Técnica de Conversão de Peça - Centro Automotivo Silva');
  }

  @override
  Widget build(BuildContext context) {
    final status = conversao.status;
    Color statusColor;
    switch (status) {
      case StatusConfiabilidade.confirmada:
        statusColor = AppTheme.successGreen;
        break;
      case StatusConfiabilidade.necessitaRevisao:
        statusColor = AppTheme.warningAmber;
        break;
      case StatusConfiabilidade.naoConfirmada:
        statusColor = AppTheme.errorRed;
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Ficha Técnica de Conversão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.silvaGold),
            onPressed: _compartilharFichaTecnica,
            tooltip: 'Compartilhar / Enviar via WhatsApp',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Card do Veículo de Aplicação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car, color: AppTheme.silvaGold, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'VEÍCULO DE APLICAÇÃO',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.silvaGold),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    const SizedBox(height: 6),
                    Text(
                      '${conversao.veiculo.montadora} ${conversao.veiculo.modelo} ${conversao.veiculo.versao}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow('Período de Fabricação:', '${conversao.veiculo.periodoAno}'),
                    _buildInfoRow('Motorização:', '${conversao.veiculo.motor} (${conversao.veiculo.combustivel})'),
                    if (conversao.veiculo.cilindrada.isNotEmpty)
                      _buildInfoRow('Cilindrada:', conversao.veiculo.cilindrada),
                    if (conversao.veiculo.observacoes.isNotEmpty)
                      _buildInfoRow('Observação do Veículo:', conversao.veiculo.observacoes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Card da Peça e Código OEM
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(conversao.peca.categoria.icone, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'DADOS DA PEÇA (${conversao.peca.categoria.nomeExibicao.toUpperCase()})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.silvaGold),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    const SizedBox(height: 6),
                    Text(
                      conversao.peca.descricao,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Posição no Veículo:', conversao.peca.posicao),
                    _buildInfoRow('Eixo:', conversao.peca.eixo),
                    _buildInfoRow('Lado:', conversao.peca.lado),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.silvaCyan.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppTheme.silvaCyan, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CÓDIGO ORIGINAL OEM (${conversao.peca.montadoraOrigem}):',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  conversao.peca.codigoOem.isNotEmpty ? conversao.peca.codigoOem : 'Não informado',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (conversao.peca.observacoesTecnicas.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow('Observações Técnicas:', conversao.peca.observacoesTecnicas),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Card de Equivalentes por Fabricante
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.compare_arrows, color: AppTheme.silvaGold, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'CÓDIGOS EQUIVALENTES (MARCAS PARALELAS)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.silvaGold),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: conversao.equivalentes.map((eq) {
                        return MarcaBadgeWidget(
                          fabricanteNome: eq.fabricanteNome,
                          codigo: eq.codigo,
                          linha: eq.linha,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Card de Confiabilidade & Auditoria
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: AppTheme.silvaGold, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'CONFIABILIDADE & AUDITORIA DE DADOS',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.silvaGold),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(status.icone, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                'Status: ${status.nomeExibicao}',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Fonte da Informação:', conversao.fonte.nomeExibicao),
                    _buildInfoRow('Responsável pelo Cadastro:', conversao.usuarioAtualizacao),
                    _buildInfoRow('Última Revisão:', '${conversao.dataAtualizacao.day.toString().padLeft(2, '0')}/${conversao.dataAtualizacao.month.toString().padLeft(2, '0')}/${conversao.dataAtualizacao.year} às ${conversao.dataAtualizacao.hour.toString().padLeft(2, '0')}:${conversao.dataAtualizacao.minute.toString().padLeft(2, '0')}'),
                    if (conversao.observacaoCompatibilidade.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Observação de Compatibilidade:', conversao.observacaoCompatibilidade),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Botão de Ação: Compartilhar / Enviar via WhatsApp
            ElevatedButton.icon(
              onPressed: _compartilharFichaTecnica,
              icon: const Icon(Icons.send, color: Colors.black),
              label: const Text(
                'ENVIAR FICHA / WHATSAPP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.silvaGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
