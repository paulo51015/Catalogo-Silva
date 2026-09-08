/// Modelo que representa um Veículo no sistema do Centro Automotivo Silva.
class VeiculoModel {
  final String id;
  final String montadora; // ex: Toyota, Volkswagen, Chevrolet, Fiat, Honda, Hyundai, Ford, Jeep
  final String modelo; // ex: Corolla, Gol, Onix, Strada, Civic, HB20, Compass, Ka
  final String versao; // ex: GLI, XEI, Altis, Comfortline, Premier, Volcano
  final int anoInicio; // ex: 2020
  final int anoFim; // ex: 2024 (ou 9999 para atual)
  final String motor; // ex: 2.0 16V, 1.0 3 Cilindros, 1.4 Turbo, 1.8 16V
  final String combustivel; // ex: Flex, Gasolina, Diesel, Híbrido
  final String cilindrada; // ex: 1987 cc, 999 cc
  final String observacoes;

  const VeiculoModel({
    required this.id,
    required this.montadora,
    required this.modelo,
    required this.versao,
    required this.anoInicio,
    required this.anoFim,
    required this.motor,
    required this.combustivel,
    required this.cilindrada,
    this.observacoes = '',
  });

  String get nomeCompleto => '$montadora $modelo $versao $motor ($anoInicio–${anoFim >= 2026 ? 'Atual' : anoFim})';
  String get periodoAno => '$anoInicio a ${anoFim >= 2026 ? 'Atual' : anoFim}';

  bool compativelComAno(int ano) => ano >= anoInicio && ano <= anoFim;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'montadora': montadora,
      'modelo': modelo,
      'versao': versao,
      'anoInicio': anoInicio,
      'anoFim': anoFim,
      'motor': motor,
      'combustivel': combustivel,
      'cilindrada': cilindrada,
      'observacoes': observacoes,
    };
  }

  factory VeiculoModel.fromMap(Map<String, dynamic> map) {
    return VeiculoModel(
      id: map['id'] ?? '',
      montadora: map['montadora'] ?? '',
      modelo: map['modelo'] ?? '',
      versao: map['versao'] ?? '',
      anoInicio: map['anoInicio'] is int ? map['anoInicio'] : int.tryParse(map['anoInicio'].toString()) ?? 2000,
      anoFim: map['anoFim'] is int ? map['anoFim'] : int.tryParse(map['anoFim'].toString()) ?? 2026,
      motor: map['motor'] ?? '',
      combustivel: map['combustivel'] ?? 'Flex',
      cilindrada: map['cilindrada'] ?? '',
      observacoes: map['observacoes'] ?? '',
    );
  }
}
