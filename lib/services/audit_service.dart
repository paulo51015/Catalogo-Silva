import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auditoria_model.dart';

/// Serviço de Auditoria para registrar histórico de alterações e governança do catálogo.
class AuditService extends ChangeNotifier {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final List<AuditoriaModel> _logs = [];
  List<AuditoriaModel> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getString('silva_audit_logs');
    if (savedLogs != null) {
      final List list = jsonDecode(savedLogs);
      _logs.clear();
      _logs.addAll(list.map((m) => AuditoriaModel.fromMap(m)));
    } else {
      // Registros iniciais de sistema
      _logs.addAll([
        AuditoriaModel(
          id: 'aud_1',
          usuarioNome: 'Sistema Silva',
          acao: 'INSERÇÃO',
          entidade: 'Base Inicial',
          descricao: 'Carga inicial do catálogo de conversões homologadas (Corolla, Gol, Onix, Strada, HB20, Compass).',
          dataHora: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    }
    notifyListeners();
  }

  Future<void> registrarAcao({
    required String usuarioNome,
    required String acao,
    required String entidade,
    required String descricao,
  }) async {
    final log = AuditoriaModel(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      usuarioNome: usuarioNome,
      acao: acao,
      entidade: entidade,
      descricao: descricao,
      dataHora: DateTime.now(),
    );

    _logs.insert(0, log);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('silva_audit_logs', jsonEncode(_logs.map((l) => l.toMap()).toList()));
    } catch (e) {
      debugPrint('Erro ao salvar log de auditoria: $e');
    }
  }
}
