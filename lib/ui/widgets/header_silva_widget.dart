import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class HeaderSilvaWidget extends StatelessWidget {
  final DatabaseService db;
  final AuthService auth;

  const HeaderSilvaWidget({
    super.key,
    required this.db,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          // Logo / Ícone Automotivo Silva
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.silvaGold, AppTheme.silvaOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build_circle, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 12),

          // Título e Identidade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CENTRO AUTOMOTIVO SILVA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.silvaGold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Text(
                  'Catálogo Inteligente de Conversão de Peças',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Badge de Usuário Ativo
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.isAdmin ? AppTheme.silvaGold.withOpacity(0.2) : AppTheme.silvaBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: user.isAdmin ? AppTheme.silvaGold : AppTheme.silvaBlue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 14,
                    color: user.isAdmin ? AppTheme.silvaGold : AppTheme.silvaCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.login.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: user.isAdmin ? AppTheme.silvaGold : AppTheme.silvaCyan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
