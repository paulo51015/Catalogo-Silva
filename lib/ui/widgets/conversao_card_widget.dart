import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../models/peca_model.dart';
import '../../theme/app_theme.dart';
import 'marca_badge_widget.dart';

class ConversaoCardWidget extends StatelessWidget {
  final ConversaoModel conversao;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorito;

  const ConversaoCardWidget({
    super.key,
    required this.conversao,
    this.onTap,
    this.onToggleFavorito,
  });

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: conversao.isFavorito ? AppTheme.silvaGold : AppTheme.dividerColor,
          width: conversao.isFavorito ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Linha Superior: Veículo & Botão de Favorito
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      conversao.peca.categoria.icone,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${conversao.veiculo.montadora.toUpperCase()} ${conversao.veiculo.modelo.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.silvaGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${conversao.veiculo.motor} • Anos: ${conversao.veiculo.periodoAno}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      conversao.isFavorito ? Icons.star : Icons.star_border,
                      color: conversao.isFavorito ? AppTheme.silvaGold : AppTheme.textSecondary,
                    ),
                    onPressed: onToggleFavorito,
                    tooltip: 'Favoritar conversão',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Descrição da Peça & Posição
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversao.peca.descricao,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Posição: ${conversao.peca.posicao} (${conversao.peca.lado})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.silvaCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Código Original OEM da Montadora
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppTheme.silvaCyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OEM ${conversao.peca.montadoraOrigem}: ',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      conversao.peca.codigoOem.isNotEmpty ? conversao.peca.codigoOem : 'Não informado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Equivalentes por Marca Paralela (COFAP, Monroe, Nakata, KYB, Bosch, etc.)
              const Text(
                'Marcas Equivalentes Cadastradas:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conversao.equivalentes.map((eq) {
                  return MarcaBadgeWidget(
                    fabricanteNome: eq.fabricanteNome,
                    codigo: eq.codigo,
                    linha: eq.linha,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 5. Rodapé: Status de Confiabilidade & Fonte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Status: ${status.nomeExibicao}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Fonte: ${conversao.fonte.nomeExibicao}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
