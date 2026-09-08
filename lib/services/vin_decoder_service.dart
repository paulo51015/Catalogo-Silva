import '../models/veiculo_model.dart';

/// Modelo de dados com o resultado detalhado da decodificação de um Chassi (VIN).
class VinDecodeResult {
  final String chassiOriginal;
  final bool isValid;
  final String? mensagemErro;
  final String wmi; // World Manufacturer Identifier (Pos 1-3)
  final String vds; // Vehicle Descriptor Section (Pos 4-9)
  final String vis; // Vehicle Identifier Section (Pos 10-17)
  final String montadora;
  final String paisOrigem;
  final String modeloSugerido;
  final int? anoModelo;
  final String plantaFabricacao;
  final String numeroSerie;
  final String motorizacaoProvavel;
  final List<String> alertasTecnicos;

  const VinDecodeResult({
    required this.chassiOriginal,
    required this.isValid,
    this.mensagemErro,
    this.wmi = '',
    this.vds = '',
    this.vis = '',
    this.montadora = '',
    this.paisOrigem = '',
    this.modeloSugerido = '',
    this.anoModelo,
    this.plantaFabricacao = '',
    this.numeroSerie = '',
    this.motorizacaoProvavel = '',
    this.alertasTecnicos = const [],
  });

  String get resumoFormatado => '$montadora $modeloSugerido ($anoModelo) - Planta: $plantaFabricacao';
}

/// Serviço Especialista em Decodificação e Validação Técnica de Chassi (VIN)
/// Padrão ISO 3779 / ABNT NBR 3 / Denatran
class VinDecoderService {
  // Tabela Oficial do 10º dígito do VIN (Ano-Modelo)
  static final Map<String, int> _anoModeloTabela = {
    '1': 2001, '2': 2002, '3': 2003, '4': 2004, '5': 2005,
    '6': 2006, '7': 2007, '8': 2008, '9': 2009, 'A': 2010,
    'B': 2011, 'C': 2012, 'D': 2013, 'E': 2014, 'F': 2015,
    'G': 2016, 'H': 2017, 'J': 2018, 'K': 2019, 'L': 2020,
    'M': 2021, 'N': 2022, 'P': 2023, 'R': 2024, 'S': 2025,
    'T': 2026, 'V': 2027, 'W': 2028, 'X': 2029, 'Y': 2030,
  };

  // Tabela WMI (Posições 1-3)
  static final Map<String, Map<String, String>> _wmiTabela = {
    // Fiat / Stellantis
    '9BD': {'montadora': 'Fiat', 'pais': 'Brasil (Betim - MG / Goiana - PE)', 'modelos': 'Strada, Palio, Uno, Toro, Argo, Mobi, Pulse, Fastback'},
    '8AP': {'montadora': 'Fiat', 'pais': 'Argentina (Córdoba)', 'modelos': 'Cronos'},
    
    // Chevrolet / General Motors
    '9BG': {'montadora': 'Chevrolet', 'pais': 'Brasil (São Caetano do Sul / Gravataí / SJC)', 'modelos': 'Onix, Prisma, Tracker, S10, Spin, Celta, Corsa, Montana, Cruze'},
    '8AG': {'montadora': 'Chevrolet', 'pais': 'Argentina (Rosario)', 'modelos': 'Cruze, Tracker'},
    
    // Volkswagen
    '9BW': {'montadora': 'Volkswagen', 'pais': 'Brasil (São Bernardo / Taubaté / S. J. dos Pinhais)', 'modelos': 'Gol, Polo, T-Cross, Nivus, Fox, Saveiro, Virtus, Voyage'},
    '8AW': {'montadora': 'Volkswagen', 'pais': 'Argentina (Pacheco)', 'modelos': 'Amarok, Taos'},
    '3VW': {'montadora': 'Volkswagen', 'pais': 'México (Puebla)', 'modelos': 'Jetta, Golf, Tiguan'},
    'WVW': {'montadora': 'Volkswagen', 'pais': 'Alemanha (Wolfsburg)', 'modelos': 'Golf GTI, Passat, Touareg'},
    
    // Toyota
    '9BR': {'montadora': 'Toyota', 'pais': 'Brasil (Indaiatuba / Sorocaba / Porto Feliz)', 'modelos': 'Corolla, Corolla Cross, Yaris, Etios'},
    '8AJ': {'montadora': 'Toyota', 'pais': 'Argentina (Zárate)', 'modelos': 'Hilux, SW4, Hiace'},
    'JTD': {'montadora': 'Toyota', 'pais': 'Japão (Toyota City)', 'modelos': 'RAV4, Prius, Camry'},
    
    // Hyundai
    '9BH': {'montadora': 'Hyundai', 'pais': 'Brasil (Piracicaba - SP)', 'modelos': 'HB20, HB20S, HB20X, Creta'},
    '95P': {'montadora': 'Hyundai (CAOA)', 'pais': 'Brasil (Anápolis - GO)', 'modelos': 'Tucson, ix35, HR, Santa Fe'},
    'KMH': {'montadora': 'Hyundai', 'pais': 'Coreia do Sul (Ulsan)', 'modelos': 'i30, Elantra, Azera, Tucson'},
    
    // Jeep / Stellantis
    '988': {'montadora': 'Jeep', 'pais': 'Brasil (Goiana - PE)', 'modelos': 'Renegade, Compass, Commander'},
    '1C4': {'montadora': 'Jeep', 'pais': 'Estados Unidos (Toledo / Detroit)', 'modelos': 'Wrangler, Cherokee, Grand Cherokee'},
    
    // Renault
    '93Y': {'montadora': 'Renault', 'pais': 'Brasil (São José dos Pinhais - PR)', 'modelos': 'Kwid, Sandero, Duster, Logan, Captur, Oroch, Megane, Kardian'},
    '8A1': {'montadora': 'Renault', 'pais': 'Argentina (Santa Isabel)', 'modelos': 'Kangoo, Alaskan'},
    
    // Honda
    '93H': {'montadora': 'Honda', 'pais': 'Brasil (Sumaré / Itirapina - SP)', 'modelos': 'Civic, Fit, HR-V, City, WR-V, CR-V'},
    'JHM': {'montadora': 'Honda', 'pais': 'Japão (Sayama / Suzuka)', 'modelos': 'Accord, CR-V, Civic Si'},
  };

  /// Decodifica um código de chassi completo de 17 caracteres.
  VinDecodeResult decodificar(String chassiInput) {
    final chassiLimpo = chassiInput.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (chassiLimpo.length != 17) {
      return VinDecodeResult(
        chassiOriginal: chassiInput,
        isValid: false,
        mensagemErro: 'O número de Chassi deve conter exatamente 17 caracteres alfanuméricos (atualmente tem ${chassiLimpo.length}).',
      );
    }

    // Não pode conter I, O, Q (segundo norma ISO 3779 para evitar confusão com 1 e 0)
    if (chassiLimpo.contains('I') || chassiLimpo.contains('O') || chassiLimpo.contains('Q')) {
      return VinDecodeResult(
        chassiOriginal: chassiInput,
        isValid: false,
        mensagemErro: 'Chassi inválido segundo a norma ISO 3779: caracteres I, O e Q não são permitidos.',
      );
    }

    final wmi = chassiLimpo.substring(0, 3);
    final vds = chassiLimpo.substring(3, 9);
    final vis = chassiLimpo.substring(9, 17);
    final digitoAno = chassiLimpo.substring(9, 10);
    final digitoPlanta = chassiLimpo.substring(10, 11);
    final serial = chassiLimpo.substring(11, 17);

    final anoModelo = _anoModeloTabela[digitoAno];
    final wmiInfo = _wmiTabela[wmi];

    String montadora = wmiInfo?['montadora'] ?? 'Montadora Não Identificada';
    String pais = wmiInfo?['pais'] ?? 'Origem Internacional';
    String modelosPossiveis = wmiInfo?['modelos'] ?? '';
    
    // Tenta inferir modelo com base no VDS
    String modeloSugerido = _inferirModelo(wmi, vds, modelosPossiveis);
    String motorizacao = _inferirMotorizacao(wmi, vds);
    String planta = _identificarPlanta(wmi, digitoPlanta);

    List<String> alertas = [];
    if (anoModelo != null) {
      if (anoModelo >= 2020) {
        alertas.add('Veículo de geração recente: verificar versões com freio eletrônico ou sensores ADAS.');
      }
      if (montadora == 'Toyota' && anoModelo >= 2020) {
        alertas.add('Corolla G12: suspensão traseira multilink (utiliza amortecedores e buchas específicos).');
      }
      if (montadora == 'Chevrolet' && anoModelo >= 2019 && modeloSugerido.contains('Onix')) {
        alertas.add('Onix Plus / Hatch plataforma GEM: correia banhada a óleo requer óleo e filtros homologados Dexos1 Gen3.');
      }
      if (montadora == 'Volkswagen' && anoModelo >= 2018) {
        alertas.add('Plataforma MQB (Polo/T-Cross/Nivus): pastilhas de freio dianteiras com sensor de desgaste integrado.');
      }
      if (montadora == 'Fiat' && anoModelo >= 2021) {
        alertas.add('Motor Firefly / GSE Turbo: verificar compatibilidade do kit de velas especiais NGK Iridium.');
      }
    }

    return VinDecodeResult(
      chassiOriginal: chassiLimpo,
      isValid: true,
      wmi: wmi,
      vds: vds,
      vis: vis,
      montadora: montadora,
      paisOrigem: pais,
      modeloSugerido: modeloSugerido,
      anoModelo: anoModelo,
      plantaFabricacao: planta,
      numeroSerie: serial,
      motorizacaoProvavel: motorizacao,
      alertasTecnicos: alertas,
    );
  }

  /// Filtra a lista de veículos cadastrados no banco para encontrar os mais compatíveis com o chassi decodificado.
  List<VeiculoModel> encontrarVeiculosCompativeis({
    required VinDecodeResult decode,
    required List<VeiculoModel> veiculosDb,
  }) {
    if (!decode.isValid) return [];

    return veiculosDb.where((v) {
      // 1. Montadora deve bater
      final matchMontadora = v.montadora.toLowerCase() == decode.montadora.toLowerCase();
      if (!matchMontadora) return false;

      // 2. Ano modelo (se identificado) deve estar dentro do range
      if (decode.anoModelo != null) {
        if (!v.compativelComAno(decode.anoModelo!)) {
          return false;
        }
      }

      // 3. Se temos modelo sugerido específico, prioriza
      if (decode.modeloSugerido.isNotEmpty && !decode.modeloSugerido.contains(',')) {
        if (!v.modelo.toLowerCase().contains(decode.modeloSugerido.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _inferirModelo(String wmi, String vds, String modelosPossiveis) {
    final vdsUpper = vds.toUpperCase();

    if (wmi == '9BR') {
      if (vdsUpper.startsWith('E') || vdsUpper.contains('COR')) return 'Corolla';
      if (vdsUpper.startsWith('K') || vdsUpper.contains('YAR')) return 'Yaris';
      if (vdsUpper.startsWith('C') || vdsUpper.contains('CROSS')) return 'Corolla Cross';
      if (vdsUpper.startsWith('B') || vdsUpper.contains('ETI')) return 'Etios';
      return 'Corolla / Yaris';
    }

    if (wmi == '8AJ') {
      if (vdsUpper.contains('HIL') || vdsUpper.startsWith('T')) return 'Hilux';
      if (vdsUpper.contains('SW4')) return 'SW4';
      return 'Hilux';
    }

    if (wmi == '9BG') {
      if (vdsUpper.contains('1B') || vdsUpper.contains('ONX') || vdsUpper.startsWith('T')) return 'Onix';
      if (vdsUpper.contains('TRK') || vdsUpper.startsWith('C')) return 'Tracker';
      if (vdsUpper.contains('S10') || vdsUpper.startsWith('13')) return 'S10';
      if (vdsUpper.contains('SPN')) return 'Spin';
      if (vdsUpper.contains('CRZ')) return 'Cruze';
      return 'Onix / Tracker';
    }

    if (wmi == '9BW') {
      if (vdsUpper.contains('GOL') || vdsUpper.startsWith('5U')) return 'Gol';
      if (vdsUpper.contains('POL') || vdsUpper.startsWith('2G')) return 'Polo';
      if (vdsUpper.contains('TCR') || vdsUpper.startsWith('2C')) return 'T-Cross';
      if (vdsUpper.contains('NIV')) return 'Nivus';
      if (vdsUpper.contains('FOX') || vdsUpper.startsWith('5Z')) return 'Fox';
      if (vdsUpper.contains('SAV')) return 'Saveiro';
      if (vdsUpper.contains('VIR')) return 'Virtus';
      return 'Gol / Polo / T-Cross';
    }

    if (wmi == '9BD') {
      if (vdsUpper.contains('STR') || vdsUpper.startsWith('28')) return 'Strada';
      if (vdsUpper.contains('TOR') || vdsUpper.startsWith('22')) return 'Toro';
      if (vdsUpper.contains('ARG') || vdsUpper.startsWith('35')) return 'Argo';
      if (vdsUpper.contains('MOB') || vdsUpper.startsWith('34')) return 'Mobi';
      if (vdsUpper.contains('PUL') || vdsUpper.startsWith('37')) return 'Pulse';
      if (vdsUpper.contains('UNO') || vdsUpper.startsWith('19')) return 'Uno';
      return 'Strada / Toro / Argo';
    }

    if (wmi == '9BH') {
      if (vdsUpper.contains('HB2') || vdsUpper.startsWith('B')) return 'HB20';
      if (vdsUpper.contains('HBS')) return 'HB20S';
      if (vdsUpper.contains('CRT') || vdsUpper.startsWith('C')) return 'Creta';
      return 'HB20 / Creta';
    }

    if (wmi == '988') {
      if (vdsUpper.contains('REN') || vdsUpper.startsWith('61')) return 'Renegade';
      if (vdsUpper.contains('COM') || vdsUpper.startsWith('62')) return 'Compass';
      if (vdsUpper.contains('CMD')) return 'Commander';
      return 'Compass / Renegade';
    }

    if (wmi == '93Y') {
      if (vdsUpper.contains('KWI') || vdsUpper.startsWith('B')) return 'Kwid';
      if (vdsUpper.contains('SAN') || vdsUpper.startsWith('B5')) return 'Sandero';
      if (vdsUpper.contains('DUS') || vdsUpper.startsWith('H7')) return 'Duster';
      if (vdsUpper.contains('LOG')) return 'Logan';
      if (vdsUpper.contains('ORO')) return 'Oroch';
      return 'Kwid / Sandero / Duster';
    }

    if (wmi == '93H') {
      if (vdsUpper.contains('CIV') || vdsUpper.startsWith('F')) return 'Civic';
      if (vdsUpper.contains('HRV') || vdsUpper.startsWith('R')) return 'HR-V';
      if (vdsUpper.contains('FIT') || vdsUpper.startsWith('G')) return 'Fit';
      if (vdsUpper.contains('CTY') || vdsUpper.startsWith('G3')) return 'City';
      return 'Civic / HR-V / Fit';
    }

    return modelosPossiveis.isNotEmpty ? modelosPossiveis.split(',').first.trim() : 'Modelo Padrão';
  }

  String _inferirMotorizacao(String wmi, String vds) {
    final vdsUpper = vds.toUpperCase();
    if (vdsUpper.contains('20') || vdsUpper.contains('2.0')) return '2.0 16V Flex';
    if (vdsUpper.contains('10') || vdsUpper.contains('1.0')) return '1.0 12V 3 Cil Flex';
    if (vdsUpper.contains('13') || vdsUpper.contains('T270')) return '1.3 Turbo T270 Flex';
    if (vdsUpper.contains('16') || vdsUpper.contains('1.6')) return '1.6 16V Flex';
    if (vdsUpper.contains('28') || vdsUpper.contains('DSL')) return '2.8 Turbo Diesel';
    if (vdsUpper.contains('HYB')) return '1.8 16V Híbrido Flex';
    return 'Motorização Homologada de Fábrica';
  }

  String _identificarPlanta(String wmi, String digitoPlanta) {
    switch (wmi) {
      case '9BR':
        return digitoPlanta == '0' ? 'Indaiatuba - SP' : 'Sorocaba - SP';
      case '9BG':
        if (digitoPlanta == '1') return 'São Caetano do Sul - SP';
        if (digitoPlanta == 'G') return 'Gravataí - RS';
        if (digitoPlanta == 'S') return 'São José dos Campos - SP';
        return 'Planta GM Brasil ($digitoPlanta)';
      case '9BW':
        if (digitoPlanta == 'P') return 'São Bernardo do Campo - SP (Anchieta)';
        if (digitoPlanta == 'T') return 'Taubaté - SP';
        if (digitoPlanta == '4') return 'São José dos Pinhais - PR';
        return 'Planta VW Brasil ($digitoPlanta)';
      case '9BD':
        return digitoPlanta == 'B' ? 'Betim - MG' : 'Goiana - PE';
      case '9BH':
        return 'Piracicaba - SP';
      case '988':
        return 'Polo Automotivo Goiana - PE';
      case '93Y':
        return 'Complexo Ayrton Senna - São José dos Pinhais - PR';
      case '93H':
        return digitoPlanta == 'S' ? 'Sumaré - SP' : 'Itirapina - SP';
      default:
        return 'Unidade de Montagem $digitoPlanta';
    }
  }
}
