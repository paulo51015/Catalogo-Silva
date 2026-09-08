import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';
import 'balcao_search_screen.dart';
import 'consulta_chassi_screen.dart';
import 'diagrama_veiculo_screen.dart';
import 'favoritos_screen.dart';
import 'gerenciamento_conversoes_screen.dart';
import 'historico_screen.dart';
import 'importador_catalogo_screen.dart';
import 'usuarios_auditoria_screen.dart';
import 'veiculos_gestao_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  final DatabaseService db;
  final AuthService auth;
  final HistoryService history;
  final AuditService audit;

  const HomeNavigationScreen({
    super.key,
    required this.db,
    required this.auth,
    required this.history,
    required this.audit,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  void _onSelectTermoFromHistory(String termo) {
    setState(() {
      _currentIndex = 0; // Volta para o balcão
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.auth.isAdmin;

    final List<Widget> screens = [
      BalcaoSearchScreen(
        db: widget.db,
        auth: widget.auth,
        history: widget.history,
        onAbrirDiagrama: () => setState(() => _currentIndex = 1),
        onAbrirChassi: () => setState(() => _currentIndex = 2),
      ),
      DiagramaVeiculoScreen(db: widget.db),
      ConsultaChassiScreen(db: widget.db),
      FavoritosScreen(db: widget.db),
      HistoricoScreen(
        history: widget.history,
        onSelectTermo: _onSelectTermoFromHistory,
      ),
      ImportadorCatalogoScreen(
        db: widget.db,
        audit: widget.audit,
        auth: widget.auth,
      ),
      if (isAdmin) ...[
        GerenciamentoConversoesScreen(
          db: widget.db,
          audit: widget.audit,
          auth: widget.auth,
        ),
        VeiculosGestaoScreen(
          db: widget.db,
          audit: widget.audit,
          auth: widget.auth,
        ),
        UsuariosAuditoriaScreen(
          auth: widget.auth,
          audit: widget.audit,
        ),
      ],
    ];

    return Scaffold(
      drawer: _buildDrawer(isAdmin),
      body: IndexedStack(
        index: _currentIndex >= screens.length ? 0 : _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex >= 5 ? 0 : _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.silvaGold,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search, color: AppTheme.silvaGold),
              label: 'Busca Balcão',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined),
              activeIcon: Icon(Icons.layers, color: AppTheme.silvaGold),
              label: 'Diagrama',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner, color: AppTheme.silvaGold),
              label: 'Chassi VIN',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border),
              activeIcon: Icon(Icons.star, color: AppTheme.silvaGold),
              label: 'Mais Usadas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history, color: AppTheme.silvaGold),
              label: 'Histórico',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(bool isAdmin) {
    final user = widget.auth.currentUser;

    return Drawer(
      backgroundColor: AppTheme.surfaceDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.surfaceDark, AppTheme.primaryDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(bottom: BorderSide(color: AppTheme.silvaGold, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.silvaGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build_circle, color: Colors.black, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CENTRO AUTOMOTIVO SILVA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.silvaGold,
                            ),
                          ),
                          Text(
                            'Catálogo Inteligente de Peças',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (user != null) ...[
                  Text(
                    'Operador: ${user.nome}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Nível: ${user.nivelAcesso.nomeExibicao}',
                    style: const TextStyle(color: AppTheme.silvaCyan, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search, color: AppTheme.silvaGold),
            title: const Text('Busca de Balcão (Principal)', style: TextStyle(color: Colors.white)),
            selected: _currentIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers, color: AppTheme.silvaGold),
            title: const Text('Diagrama Visual Interativo (Hover)', style: TextStyle(color: Colors.white)),
            selected: _currentIndex == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: AppTheme.silvaGold),
            title: const Text('Consulta por Chassi (VIN 17 Dígitos)', style: TextStyle(color: Colors.white)),
            selected: _currentIndex == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: AppTheme.silvaGold),
            title: const Text('Mais Utilizadas (Favoritos)', style: TextStyle(color: Colors.white)),
            selected: _currentIndex == 3,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppTheme.silvaGold),
            title: const Text('Histórico de Pesquisas', style: TextStyle(color: Colors.white)),
            selected: _currentIndex == 4,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: AppTheme.silvaGold),
            title: const Text('Importar Planilhas (Excel/CSV)', style: TextStyle(color: Colors.white)),
            selected: _currentIndex == 5,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 5);
            },
          ),
          const Divider(color: AppTheme.dividerColor),

          // Seção Administrativa
          if (isAdmin) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'ADMINISTRAÇÃO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: AppTheme.silvaCyan),
              title: const Text('Gestão de Conversões', style: TextStyle(color: Colors.white)),
              selected: _currentIndex == 6,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 6);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: AppTheme.silvaCyan),
              title: const Text('Gestão de Veículos', style: TextStyle(color: Colors.white)),
              selected: _currentIndex == 7,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 7);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppTheme.silvaCyan),
              title: const Text('Usuários & Auditoria', style: TextStyle(color: Colors.white)),
              selected: _currentIndex == 8,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 8);
              },
            ),
            const Divider(color: AppTheme.dividerColor),
          ],

          ListTile(
            leading: const Icon(Icons.refresh, color: AppTheme.warningAmber),
            title: const Text('Restaurar Base Padrão Silva (8 Montadoras)', style: TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restaurar Catálogo Oficial?'),
                  content: const Text('Isso restaurará a base padrão oficial com as 8 principais montadoras (Toyota, VW, GM, Fiat, Hyundai, Jeep, Renault, Honda).'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                    ElevatedButton(
                      onPressed: () {
                        widget.db.resetarBaseParaPadrao();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Base Oficial das 8 Montadoras restaurada com sucesso!')),
                        );
                      },
                      child: const Text('RESTAURAR'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorRed),
            title: const Text('Sair da Conta', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              widget.auth.logout();
            },
          ),
        ],
      ),
    );
  }
}
