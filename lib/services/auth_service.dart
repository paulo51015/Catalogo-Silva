import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';

/// Serviço de Autenticação e Controle de Acesso por Níveis (RBAC).
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UsuarioModel? _currentUser;
  UsuarioModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  final List<UsuarioModel> _usuariosCadastrados = [
    const UsuarioModel(
      id: 'usr_admin',
      nome: 'Administrador Silva',
      login: 'admin',
      senha: '123', // Padrão solicitado
      nivelAcesso: NivelAcesso.administrador,
    ),
    const UsuarioModel(
      id: 'usr_balcao',
      nome: 'Colaborador Balcão',
      login: 'balcao',
      senha: '123',
      nivelAcesso: NivelAcesso.colaborador,
    ),
    const UsuarioModel(
      id: 'usr_carlos',
      nome: 'Carlos Silva (Consultor)',
      login: 'carlos',
      senha: '123',
      nivelAcesso: NivelAcesso.colaborador,
    ),
  ];

  List<UsuarioModel> get usuarios => List.unmodifiable(_usuariosCadastrados);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogin = prefs.getString('silva_logged_user');
    if (savedLogin != null) {
      final user = _usuariosCadastrados.firstWhere(
        (u) => u.login == savedLogin,
        orElse: () => _usuariosCadastrados.first,
      );
      _currentUser = user;
      notifyListeners();
    } else {
      // Entra como administrador por padrão para uso imediato no balcão
      _currentUser = _usuariosCadastrados.first;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    final user = _usuariosCadastrados.firstWhere(
      (u) => u.login.trim().toLowerCase() == username.trim().toLowerCase() && u.senha == password,
      orElse: () => const UsuarioModel(id: '', nome: '', login: '', senha: ''),
    );

    if (user.id.isNotEmpty) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('silva_logged_user', user.login);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('silva_logged_user');
    notifyListeners();
  }

  Future<void> alternarUsuarioRapido(UsuarioModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('silva_logged_user', user.login);
    notifyListeners();
  }
}
