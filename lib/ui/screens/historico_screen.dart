import 'package:flutter/material.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';

class HistoricoScreen extends StatelessWidget {
  final HistoryService history;
  final ValueChanged<String> onSelectTermo;

  const HistoricoScreen({
    super.key,
    required this.history,
    required this.onSelectTermo,
  });

  @override
  Widget build(BuildContext context) {
    final list = history.historico;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history, color: AppTheme.silvaGold),
            SizedBox(width: 8),
            Text('Histórico de Pesquisas'),
          ],
        ),
        actions: [
          if (list.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              tooltip: 'Limpar Histórico',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar Histórico?'),
                    content: const Text('Deseja apagar todas as pesquisas recentes registradas?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                      ElevatedButton(
                        onPressed: () {
                          history.limparHistorico();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                        child: const Text('LIMPAR', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma pesquisa registrada recentemente.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(color: AppTheme.dividerColor),
              itemBuilder: (context, index) {
                final item = list[index];
                final data = item.dataHora;
                final dataStr = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.surfaceLight,
                    child: Icon(Icons.search, color: AppTheme.silvaGold, size: 20),
                  ),
                  title: Text(
                    item.termoPesquisa,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  subtitle: Text(
                    '$dataStr • ${item.totalResultados} resultado(s)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.silvaCyan),
                  onTap: () {
                    onSelectTermo(item.termoPesquisa);
                  },
                );
              },
            ),
    );
  }
}
