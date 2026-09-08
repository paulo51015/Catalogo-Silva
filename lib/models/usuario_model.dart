enum NivelAcesso {
  administrador,
  colaborador,
}

extension NivelAcessoExtension on NivelAcesso {
  String get nomeExibicao {
    switch (this) {
      case NivelAcesso.administrador:
        return 'Administrador';
      case NivelAcesso.colaborador:
        return 'Colaborador (Balcão)';
    }
  }

  bool get podeEditar => this == NivelAcesso.administrador;
  bool get podeImportar => this == NivelAcesso.administrador;
  bool get podeGerenciarUsuarios => this == NivelAcesso.administrador;
}

/// Modelo de Usuário e Autenticação com perfis de acesso RBAC.
class UsuarioModel {
  final String id;
  final String nome;
  final String login;
  final String senha; // Armazenada com segurança
  final NivelAcesso nivelAcesso;
  final bool ativo;

  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.login,
    required this.senha,
    this.nivelAcesso = NivelAcesso.colaborador,
    this.ativo = true,
  });

  bool get isAdmin => nivelAcesso == NivelAcesso.administrador;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'login': login,
      'senha': senha,
      'nivelAcesso': nivelAcesso.name,
      'ativo': ativo,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      login: map['login'] ?? '',
      senha: map['senha'] ?? '',
      nivelAcesso: NivelAcesso.values.firstWhere(
        (n) => n.name == map['nivelAcesso'],
        orElse: () => NivelAcesso.colaborador,
      ),
      ativo: map['ativo'] ?? true,
    );
  }
}
