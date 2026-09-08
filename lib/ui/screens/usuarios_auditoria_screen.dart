import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class UsuariosAuditoriaScreen extends StatelessWidget {
  final AuthService auth;
  final AuditService audit;

  const UsuariosAuditoriaScreen({
    super.key,
    required this.auth,
    required this.audit,
  });

  @override
  Widget build(BuildContext context) {
    final usuarios = auth.usuarios;
    final logs = audit.logs;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          title: const Text('Usuários & Auditoria de Dados'),
          bottom: const TabBar(
            indicatorColor: AppTheme.silvaGold,
            labelColor: AppTheme.silvaGold,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuários & Perfis'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Log de Auditoria'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba 1: Usuários
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final u = usuarios[index];
                final isCurrent = auth.currentUser?.id == u.id;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: u.isAdmin ? AppTheme.silvaGold : AppTheme.silvaBlue,
                      child: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.black),
                    ),
                    title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('Login: ${u.login} • Nível: ${u.nivelAcesso.nomeExibicao}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: isCurrent
                        ? const Chip(label: Text('ATIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
                        : ElevatedButton(
                            onPressed: () => auth.alternarUsuarioRapido(u),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceLight,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('Alternar', style: TextStyle(color: AppTheme.silvaCyan, fontSize: 12)),
                          ),
                  ),
                );
              },
            ),

            // Aba 2: Log de Auditoria
            logs.isEmpty
                ? const Center(child: Text('Nenhum log de auditoria registrado.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.dividerColor),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final d = log.dataHora;
                      final dataStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} às ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

                      Color badgeColor = AppTheme.silvaCyan;
                      if (log.acao == 'EXCLUSÃO') badgeColor = AppTheme.errorRed;
                      if (log.acao == 'INSERÇÃO' || log.acao == 'IMPORTAÇÃO PLANILHA') badgeColor = AppTheme.successGreen;
                      if (log.acao == 'EDIÇÃO') badgeColor = AppTheme.warningAmber;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor),
                              ),
                              child: Text(
                                log.acao,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.descricao,
                                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Por ${log.usuarioNome} em $dataStr',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
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
  }
}
