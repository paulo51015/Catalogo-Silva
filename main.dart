import 'package:flutter/material.dart';
import 'services/audit_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/history_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_navigation_screen.dart';
import 'ui/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseService();
  final auth = AuthService();
  final history = HistoryService();
  final audit = AuditService();

  await db.init();
  await auth.init();
  await history.init();
  await audit.init();

  runApp(CatalogoSilvaApp(
    db: db,
    auth: auth,
    history: history,
    audit: audit,
  ));
}

class CatalogoSilvaApp extends StatelessWidget {
  final DatabaseService db;
  final AuthService auth;
  final HistoryService history;
  final AuditService audit;

  const CatalogoSilvaApp({
    super.key,
    required this.db,
    required this.auth,
    required this.history,
    required this.audit,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        return MaterialApp(
          title: 'Catálogo Inteligente - Centro Automotivo Silva',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: auth.isAuthenticated
              ? HomeNavigationScreen(
                  db: db,
                  auth: auth,
                  history: history,
                  audit: audit,
                )
              : LoginScreen(
                  auth: auth,
                  onLoginSuccess: () {},
                ),
        );
      },
    );
  }
}
