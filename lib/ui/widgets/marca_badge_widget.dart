import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MarcaBadgeWidget extends StatelessWidget {
  final String fabricanteNome;
  final String codigo;
  final String? linha;

  const MarcaBadgeWidget({
    super.key,
    required this.fabricanteNome,
    required this.codigo,
    this.linha,
  });

  Color _getBrandColor(String brand) {
    final b = brand.toUpperCase().trim();
    if (b.contains('COFAP')) return const Color(0xFFFFCC00);
    if (b.contains('MONROE')) return const Color(0xFF0077B6);
    if (b.contains('NAKATA')) return const Color(0xFF00A86B);
    if (b.contains('KYB')) return const Color(0xFF90E0EF);
    if (b.contains('BOSCH')) return const Color(0xFFE63946);
    if (b.contains('FRAS')) return const Color(0xFFF77F00);
    if (b.contains('TRW')) return const Color(0xFFD62828);
    if (b.contains('MAHLE')) return const Color(0xFF4361EE);
    if (b.contains('NGK')) return const Color(0xFF007F5F);
    if (b.contains('SKF')) return const Color(0xFF0072BB);
    if (b.contains('LUK')) return const Color(0xFFFFB703);
    return AppTheme.silvaCyan;
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = _getBrandColor(fabricanteNome);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brandColor.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fabricanteNome.toUpperCase(),
              style: TextStyle(
                color: brandColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            codigo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (linha != null && linha!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              '($linha)',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
