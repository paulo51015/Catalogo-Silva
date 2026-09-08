import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.auth,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController(text: 'admin');
  final TextEditingController _passController = TextEditingController(text: '123');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin([String? u, String? p]) async {
    final user = u ?? _userController.text.trim();
    final pass = p ?? _passController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.auth.login(user, pass);
    setState(() => _isLoading = false);

    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = 'Usuário ou senha inválidos. Utilize admin/123 ou balcao/123.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.silvaGold, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Centro Automotivo Silva
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.silvaGold, AppTheme.silvaOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.silvaGold.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.build_circle, color: Colors.black, size: 48),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'CENTRO AUTOMOTIVO SILVA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.silvaGold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Catálogo Inteligente de Conversão de Peças',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.errorRed),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person, color: AppTheme.silvaGold),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock, color: AppTheme.silvaGold),
                      ),
                    ),
                    const SizedBox(height: 22),

                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleLogin(),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('ENTRAR NO SISTEMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 20),

                    // Acesso Rápido de Demonstração
                    const Text(
                      'Acessos Rápidos de Demonstração:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleLogin('admin', '123'),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.silvaGold)),
                            child: const Text('Admin', style: TextStyle(color: AppTheme.silvaGold, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleLogin('balcao', '123'),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.silvaCyan)),
                            child: const Text('Balcão', style: TextStyle(color: AppTheme.silvaCyan, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
