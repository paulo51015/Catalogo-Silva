import 'package:flutter/material.dart';
import '../../models/veiculo_model.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class VeiculosGestaoScreen extends StatefulWidget {
  final DatabaseService db;
  final AuditService audit;
  final AuthService auth;

  const VeiculosGestaoScreen({
    super.key,
    required this.db,
    required this.audit,
    required this.auth,
  });

  @override
  State<VeiculosGestaoScreen> createState() => _VeiculosGestaoScreenState();
}

class _VeiculosGestaoScreenState extends State<VeiculosGestaoScreen> {
  void _abrirModalVeiculo([VeiculoModel? edicao]) {
    final bool isEdit = edicao != null;

    final montadoraController = TextEditingController(text: isEdit ? edicao.montadora : 'Toyota');
    final modeloController = TextEditingController(text: isEdit ? edicao.modelo : '');
    final versaoController = TextEditingController(text: isEdit ? edicao.versao : 'Todas');
    final anoInicioController = TextEditingController(text: isEdit ? edicao.anoInicio.toString() : '2020');
    final anoFimController = TextEditingController(text: isEdit ? edicao.anoFim.toString() : '2024');
    final motorController = TextEditingController(text: isEdit ? edicao.motor : '1.0');
    final combustivelController = TextEditingController(text: isEdit ? edicao.combustivel : 'Flex');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar Veículo' : 'Cadastrar Novo Veículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: montadoraController, decoration: const InputDecoration(labelText: 'Montadora (ex: Toyota)')),
              const SizedBox(height: 8),
              TextField(controller: modeloController, decoration: const InputDecoration(labelText: 'Modelo (ex: Corolla)')),
              const SizedBox(height: 8),
              TextField(controller: versaoController, decoration: const InputDecoration(labelText: 'Versão')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: anoInicioController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ano Início'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: anoFimController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ano Fim'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: motorController, decoration: const InputDecoration(labelText: 'Motor (ex: 2.0 16V)')),
              const SizedBox(height: 8),
              TextField(controller: combustivelController, decoration: const InputDecoration(labelText: 'Combustível (Flex / Gasolina)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (montadoraController.text.trim().isEmpty || modeloController.text.trim().isEmpty) return;

              final veiculo = VeiculoModel(
                id: isEdit ? edicao.id : 'v_${DateTime.now().millisecondsSinceEpoch}',
                montadora: montadoraController.text.trim(),
                modelo: modeloController.text.trim(),
                versao: versaoController.text.trim(),
                anoInicio: int.tryParse(anoInicioController.text.trim()) ?? 2020,
                anoFim: int.tryParse(anoFimController.text.trim()) ?? 2024,
                motor: motorController.text.trim(),
                combustivel: combustivelController.text.trim(),
                cilindrada: '',
              );

              widget.db.addVeiculo(veiculo);
              widget.audit.registrarAcao(
                usuarioNome: widget.auth.currentUser?.nome ?? 'Admin',
                acao: isEdit ? 'EDIÇÃO' : 'INSERÇÃO',
                entidade: 'Veículo',
                descricao: '${isEdit ? 'Atualizado' : 'Cadastrado'} veículo ${veiculo.nomeCompleto}',
              );

              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.db.veiculos;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Cadastro de Veículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.silvaGold, size: 28),
            onPressed: () => _abrirModalVeiculo(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final v = list[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceLight,
                child: Icon(Icons.directions_car, color: AppTheme.silvaGold),
              ),
              title: Text(
                '${v.montadora} ${v.modelo} ${v.versao}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                '${v.motor} (${v.combustivel}) • Anos: ${v.periodoAno}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.silvaCyan, size: 20),
                    onPressed: () => _abrirModalVeiculo(v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorRed, size: 20),
                    onPressed: () {
                      widget.db.deleteVeiculo(v.id);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
