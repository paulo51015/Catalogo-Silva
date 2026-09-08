import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversao_model.dart';
import '../models/fabricante_model.dart';
import '../models/peca_model.dart';
import '../models/veiculo_model.dart';

/// Serviço de Banco de Dados Local do Centro Automotivo Silva.
/// Mantém a integridade relacional, indexação de códigos e persistência.
class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final List<VeiculoModel> _veiculos = [];
  final List<PecaModel> _pecas = [];
  final List<FabricanteModel> _fabricantes = [];
  final List<ConversaoModel> _conversoes = [];

  List<VeiculoModel> get veiculos => List.unmodifiable(_veiculos);
  List<PecaModel> get pecas => List.unmodifiable(_pecas);
  List<FabricanteModel> get fabricantes => List.unmodifiable(_fabricantes);
  List<ConversaoModel> get conversoes => List.unmodifiable(_conversoes);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializa o banco de dados carregando registros salvos ou populando com a base original do Silva.
  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedConversoes = prefs.getString('silva_conversoes_data_v2');

    if (savedConversoes != null && savedConversoes.isNotEmpty) {
      try {
        _carregarDoStorage(prefs);
      } catch (e) {
        debugPrint('Erro ao carregar do storage local, populando base padrão: $e');
        _popularBasePadraoSilva();
      }
    } else {
      _popularBasePadraoSilva();
      await _salvarNoStorage();
    }

    _isInitialized = true;
    notifyListeners();
  }

  // --- CRUD VEÍCULOS ---

  Future<void> addVeiculo(VeiculoModel veiculo) async {
    _veiculos.removeWhere((v) => v.id == veiculo.id);
    _veiculos.add(veiculo);
    await _salvarNoStorage();
    notifyListeners();
  }

  Future<void> deleteVeiculo(String id) async {
    _veiculos.removeWhere((v) => v.id == id);
    _conversoes.removeWhere((c) => c.veiculo.id == id);
    await _salvarNoStorage();
    notifyListeners();
  }

  // --- CRUD PEÇAS ---

  Future<void> addPeca(PecaModel peca) async {
    _pecas.removeWhere((p) => p.id == peca.id);
    _pecas.add(peca);
    await _salvarNoStorage();
    notifyListeners();
  }

  Future<void> deletePeca(String id) async {
    _pecas.removeWhere((p) => p.id == id);
    _conversoes.removeWhere((c) => c.peca.id == id);
    await _salvarNoStorage();
    notifyListeners();
  }

  // --- CRUD FABRICANTES ---

  Future<void> addFabricante(FabricanteModel fabricante) async {
    _fabricantes.removeWhere((f) => f.id == fabricante.id);
    _fabricantes.add(fabricante);
    await _salvarNoStorage();
    notifyListeners();
  }

  // --- CRUD CONVERSÕES ---

  Future<void> addConversao(ConversaoModel conversao) async {
    _conversoes.removeWhere((c) => c.id == conversao.id);
    _conversoes.insert(0, conversao);
    await _salvarNoStorage();
    notifyListeners();
  }

  Future<void> updateConversao(ConversaoModel conversao) async {
    final idx = _conversoes.indexWhere((c) => c.id == conversao.id);
    if (idx != -1) {
      _conversoes[idx] = conversao;
      await _salvarNoStorage();
      notifyListeners();
    }
  }

  Future<void> deleteConversao(String id) async {
    _conversoes.removeWhere((c) => c.id == id);
    await _salvarNoStorage();
    notifyListeners();
  }

  Future<void> toggleFavorito(String id) async {
    final idx = _conversoes.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final item = _conversoes[idx];
      _conversoes[idx] = item.copyWith(isFavorito: !item.isFavorito);
      await _salvarNoStorage();
      notifyListeners();
    }
  }

  // --- PERSISTÊNCIA ---

  Future<void> _salvarNoStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('silva_fabricantes_data', jsonEncode(_fabricantes.map((f) => f.toMap()).toList()));
    await prefs.setString('silva_veiculos_data', jsonEncode(_veiculos.map((v) => v.toMap()).toList()));
    await prefs.setString('silva_pecas_data', jsonEncode(_pecas.map((p) => p.toMap()).toList()));
    await prefs.setString('silva_conversoes_data_v2', jsonEncode(_conversoes.map((c) => c.toMap()).toList()));
  }

  void _carregarDoStorage(SharedPreferences prefs) {
    final fabStr = prefs.getString('silva_fabricantes_data');
    final veicStr = prefs.getString('silva_veiculos_data');
    final pecaStr = prefs.getString('silva_pecas_data');
    final convStr = prefs.getString('silva_conversoes_data_v2');

    if (fabStr != null) {
      final List list = jsonDecode(fabStr);
      _fabricantes.clear();
      _fabricantes.addAll(list.map((m) => FabricanteModel.fromMap(m)));
    }

    if (veicStr != null) {
      final List list = jsonDecode(veicStr);
      _veiculos.clear();
      _veiculos.addAll(list.map((m) => VeiculoModel.fromMap(m)));
    }

    if (pecaStr != null) {
      final List list = jsonDecode(pecaStr);
      _pecas.clear();
      _pecas.addAll(list.map((m) => PecaModel.fromMap(m)));
    }

    if (convStr != null) {
      final List list = jsonDecode(convStr);
      _conversoes.clear();
      _conversoes.addAll(list.map((m) => ConversaoModel.fromMap(m)));
    }
  }

  /// Restaura o banco de dados para os dados oficiais de catálogo do Centro Automotivo Silva.
  Future<void> resetarBaseParaPadrao() async {
    _popularBasePadraoSilva();
    await _salvarNoStorage();
    notifyListeners();
  }

  // --- POPULAÇÃO DA BASE AUTOMOTIVA OFICIAL (8 MONTADORAS) ---

  void _popularBasePadraoSilva() {
    _fabricantes.clear();
    _fabricantes.addAll([
      const FabricanteModel(id: 'fab_cofap', nome: 'COFAP', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_monroe', nome: 'MONROE', paisOrigem: 'EUA / Brasil'),
      const FabricanteModel(id: 'fab_nakata', nome: 'NAKATA', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_kyb', nome: 'KYB', paisOrigem: 'Japão'),
      const FabricanteModel(id: 'fab_bosch', nome: 'BOSCH', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_frasle', nome: 'FRAS-LE', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_trw', nome: 'TRW', paisOrigem: 'Alemanha / Brasil'),
      const FabricanteModel(id: 'fab_mahle', nome: 'MAHLE', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_mann', nome: 'MANN-FILTER', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_ngk', nome: 'NGK', paisOrigem: 'Japão'),
      const FabricanteModel(id: 'fab_skf', nome: 'SKF', paisOrigem: 'Suécia'),
      const FabricanteModel(id: 'fab_luk', nome: 'LUK', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_sachs', nome: 'SACHS', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_valeo', nome: 'VALEO', paisOrigem: 'França'),
      const FabricanteModel(id: 'fab_cobreq', nome: 'COBREQ', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_dayco', nome: 'DAYCO', paisOrigem: 'EUA / Brasil'),
      const FabricanteModel(id: 'fab_gates', nome: 'GATES', paisOrigem: 'EUA'),
      const FabricanteModel(id: 'fab_magneti', nome: 'MAGNETI MARELLI', paisOrigem: 'Itália / Brasil'),
      const FabricanteModel(id: 'fab_viemar', nome: 'VIEMAR', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_axios', nome: 'AXIOS', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_controil', nome: 'CONTROIL', paisOrigem: 'Brasil'),
    ]);

    // 1. TOYOTA
    final vCorolla2020 = const VeiculoModel(
      id: 'v_corolla_2020',
      montadora: 'Toyota',
      modelo: 'Corolla',
      versao: 'GLI / XEI / Altis Premium',
      anoInicio: 2020,
      anoFim: 2025,
      motor: '2.0 16V Dynamic Force',
      combustivel: 'Flex',
      cilindrada: '1987 cc',
      observacoes: 'Geração G12 (Chassi 9BR), suspensão traseira multilink.',
    );

    final vHilux2016 = const VeiculoModel(
      id: 'v_hilux_2016',
      montadora: 'Toyota',
      modelo: 'Hilux',
      versao: 'SRX / SRV / STD 4x4',
      anoInicio: 2016,
      anoFim: 2025,
      motor: '2.8 16V D-4D Turbo Diesel',
      combustivel: 'Diesel',
      cilindrada: '2755 cc',
      observacoes: 'Geração 8 (Chassi 8AJ Zárate), feixe de molas traseiro.',
    );

    final vYaris2018 = const VeiculoModel(
      id: 'v_yaris_2018',
      montadora: 'Toyota',
      modelo: 'Yaris',
      versao: 'XL / XS / XLS',
      anoInicio: 2018,
      anoFim: 2025,
      motor: '1.5 16V Dual VVT-i',
      combustivel: 'Flex',
      cilindrada: '1496 cc',
      observacoes: 'Plataforma XP150 (Chassi 9BR Sorocaba).',
    );

    // 2. VOLKSWAGEN
    final vGolG6 = const VeiculoModel(
      id: 'v_gol_g6',
      montadora: 'Volkswagen',
      modelo: 'Gol',
      versao: 'Trendline / Comfortline / Highline',
      anoInicio: 2013,
      anoFim: 2023,
      motor: '1.6 8V EA111 / 1.0 12V EA211',
      combustivel: 'Flex',
      cilindrada: '1598 cc',
      observacoes: 'Plataforma PQ24 (Chassi 9BW Taubaté/São Bernardo).',
    );

    final vPoloMQB = const VeiculoModel(
      id: 'v_polo_mqb',
      montadora: 'Volkswagen',
      modelo: 'Polo',
      versao: 'MPI / TSI / Comfortline / Highline',
      anoInicio: 2018,
      anoFim: 2025,
      motor: '1.0 12V 200 TSI EA211',
      combustivel: 'Flex',
      cilindrada: '999 cc',
      observacoes: 'Plataforma MQB-A0 (Chassi 9BW Anchieta).',
    );

    final vTCross = const VeiculoModel(
      id: 'v_tcross',
      montadora: 'Volkswagen',
      modelo: 'T-Cross',
      versao: '200 TSI / 250 TSI Highline',
      anoInicio: 2019,
      anoFim: 2025,
      motor: '1.4 16V 250 TSI / 1.0 200 TSI',
      combustivel: 'Flex',
      cilindrada: '1395 cc',
      observacoes: 'Plataforma MQB (Chassi 9BW São José dos Pinhais).',
    );

    // 3. CHEVROLET / GM
    final vOnix2019 = const VeiculoModel(
      id: 'v_onix_2019',
      montadora: 'Chevrolet',
      modelo: 'Onix',
      versao: 'LT / LTZ / Premier / RS',
      anoInicio: 2019,
      anoFim: 2025,
      motor: '1.0 12V 3 Cil Turbo CSS Prime',
      combustivel: 'Flex',
      cilindrada: '999 cc',
      observacoes: 'Plataforma GEM (Chassi 9BG Gravataí), correia banhada a óleo.',
    );

    final vTracker2020 = const VeiculoModel(
      id: 'v_tracker_2020',
      montadora: 'Chevrolet',
      modelo: 'Tracker',
      versao: 'LT / LTZ / Premier',
      anoInicio: 2020,
      anoFim: 2025,
      motor: '1.2 Turbo / 1.0 Turbo CSS Prime',
      combustivel: 'Flex',
      cilindrada: '1199 cc',
      observacoes: 'Plataforma GEM (Chassi 9BG São Caetano do Sul).',
    );

    final vS102012 = const VeiculoModel(
      id: 'v_s10_2012',
      montadora: 'Chevrolet',
      modelo: 'S10',
      versao: 'LT / LTZ / High Country 4x4',
      anoInicio: 2012,
      anoFim: 2024,
      motor: '2.8 16V CTDI Turbo Diesel',
      combustivel: 'Diesel',
      cilindrada: '2776 cc',
      observacoes: 'Chassi 9BG São José dos Campos, suspensão reforçada.',
    );

    // 4. FIAT
    final vStrada2020 = const VeiculoModel(
      id: 'v_strada_2020',
      montadora: 'Fiat',
      modelo: 'Strada',
      versao: 'Endurance / Freedom / Volcano / Ranch',
      anoInicio: 2020,
      anoFim: 2025,
      motor: '1.3 8V Firefly / 1.0 Turbo T200',
      combustivel: 'Flex',
      cilindrada: '1332 cc',
      observacoes: 'Plataforma MPP (Chassi 9BD Betim), feixe parabólico traseiro.',
    );

    final vToro2016 = const VeiculoModel(
      id: 'v_toro_2016',
      montadora: 'Fiat',
      modelo: 'Toro',
      versao: 'Freedom / Volcano / Ultra / Ranch',
      anoInicio: 2016,
      anoFim: 2025,
      motor: '1.3 Turbo T270 / 2.0 Multijet Diesel',
      combustivel: 'Flex / Diesel',
      cilindrada: '1332 cc',
      observacoes: 'Plataforma Small Wide (Chassi 9BD Goiana), suspensão multilink.',
    );

    final vArgo2017 = const VeiculoModel(
      id: 'v_argo_2017',
      montadora: 'Fiat',
      modelo: 'Argo',
      versao: 'Drive / Trekking / Precision',
      anoInicio: 2017,
      anoFim: 2025,
      motor: '1.0 6V Firefly / 1.3 8V Firefly',
      combustivel: 'Flex',
      cilindrada: '999 cc',
      observacoes: 'Plataforma MP1 (Chassi 9BD Betim).',
    );

    // 5. HYUNDAI
    final vHB202019 = const VeiculoModel(
      id: 'v_hb20_2019',
      montadora: 'Hyundai',
      modelo: 'HB20',
      versao: 'Sense / Evolution / Diamond / Platinum',
      anoInicio: 2019,
      anoFim: 2025,
      motor: '1.0 12V Kappa 3 Cil / 1.0 TGDI Turbo',
      combustivel: 'Flex',
      cilindrada: '998 cc',
      observacoes: 'Geração 2 (Chassi 9BH Piracicaba).',
    );

    final vCreta2017 = const VeiculoModel(
      id: 'v_creta_2017',
      montadora: 'Hyundai',
      modelo: 'Creta',
      versao: 'Attitude / Pulse / Prestige / Ultimate',
      anoInicio: 2017,
      anoFim: 2025,
      motor: '1.6 16V Gamma / 1.0 TGDI / 2.0 Nu',
      combustivel: 'Flex',
      cilindrada: '1591 cc',
      observacoes: 'Plataforma GB (Chassi 9BH Piracicaba).',
    );

    // 6. JEEP
    final vRenegade2015 = const VeiculoModel(
      id: 'v_renegade_2015',
      montadora: 'Jeep',
      modelo: 'Renegade',
      versao: 'Sport / Longitude / Trailhawk',
      anoInicio: 2015,
      anoFim: 2025,
      motor: '1.3 Turbo T270 / 1.8 16V E.torQ / 2.0 Diesel',
      combustivel: 'Flex / Diesel',
      cilindrada: '1332 cc',
      observacoes: 'Plataforma Small Wide 4x4 (Chassi 988 Goiana).',
    );

    final vCompass2017 = const VeiculoModel(
      id: 'v_compass_2017',
      montadora: 'Jeep',
      modelo: 'Compass',
      versao: 'Sport / Longitude / Limited / Trailhawk',
      anoInicio: 2017,
      anoFim: 2025,
      motor: '1.3 Turbo T270 / 2.0 Multijet Diesel',
      combustivel: 'Flex / Diesel',
      cilindrada: '1332 cc',
      observacoes: 'Plataforma Small Wide LWB (Chassi 988 Goiana).',
    );

    // 7. RENAULT
    final vKwid2017 = const VeiculoModel(
      id: 'v_kwid_2017',
      montadora: 'Renault',
      modelo: 'Kwid',
      versao: 'Life / Zen / Intense / Outsider',
      anoInicio: 2017,
      anoFim: 2025,
      motor: '1.0 12V 3 Cil SCe B4D',
      combustivel: 'Flex',
      cilindrada: '999 cc',
      observacoes: 'Plataforma CMF-A (Chassi 93Y São José dos Pinhais), cubo de roda 3 furos.',
    );

    final vSandero2014 = const VeiculoModel(
      id: 'v_sandero_2014',
      montadora: 'Renault',
      modelo: 'Sandero',
      versao: 'Authentique / Expression / Stepway / RS',
      anoInicio: 2014,
      anoFim: 2024,
      motor: '1.0 12V SCe / 1.6 16V SCe / 2.0 F4R',
      combustivel: 'Flex',
      cilindrada: '1597 cc',
      observacoes: 'Plataforma B0 (Chassi 93Y São José dos Pinhais).',
    );

    final vDuster2015 = const VeiculoModel(
      id: 'v_duster_2015',
      montadora: 'Renault',
      modelo: 'Duster',
      versao: 'Dynamique / Iconic / Intense 4x4',
      anoInicio: 2015,
      anoFim: 2025,
      motor: '1.6 16V SCe / 1.3 TCe Turbo',
      combustivel: 'Flex',
      cilindrada: '1597 cc',
      observacoes: 'Plataforma B0 (Chassi 93Y São José dos Pinhais).',
    );

    // 8. HONDA
    final vCivicG10 = const VeiculoModel(
      id: 'v_civic_g10',
      montadora: 'Honda',
      modelo: 'Civic',
      versao: 'Sport / EXL / Touring G10',
      anoInicio: 2016,
      anoFim: 2021,
      motor: '2.0 16V i-VTEC / 1.5 Turbo Touring',
      combustivel: 'Flex / Gasolina',
      cilindrada: '1997 cc',
      observacoes: 'Geração 10 (Chassi 93H Sumaré/Itirapina), suspensão traseira multilink.',
    );

    final vHRV2015 = const VeiculoModel(
      id: 'v_hrv_2015',
      montadora: 'Honda',
      modelo: 'HR-V',
      versao: 'LX / EX / EXL / Touring',
      anoInicio: 2015,
      anoFim: 2025,
      motor: '1.8 16V i-VTEC / 1.5 DI i-VTEC',
      combustivel: 'Flex',
      cilindrada: '1799 cc',
      observacoes: 'Plataforma Global Small Car (Chassi 93H Sumaré/Itirapina).',
    );

    final vFit2015 = const VeiculoModel(
      id: 'v_fit_2015',
      montadora: 'Honda',
      modelo: 'Fit',
      versao: 'DX / LX / EX / EXL',
      anoInicio: 2015,
      anoFim: 2021,
      motor: '1.5 16V i-VTEC FlexOne',
      combustivel: 'Flex',
      cilindrada: '1497 cc',
      observacoes: 'Geração 3 (Chassi 93H Sumaré).',
    );

    _veiculos.clear();
    _veiculos.addAll([
      vCorolla2020, vHilux2016, vYaris2018,
      vGolG6, vPoloMQB, vTCross,
      vOnix2019, vTracker2020, vS102012,
      vStrada2020, vToro2016, vArgo2017,
      vHB202019, vCreta2017,
      vRenegade2015, vCompass2017,
      vKwid2017, vSandero2014, vDuster2015,
      vCivicG10, vHRV2015, vFit2015,
    ]);

    // --- CADASTRO DE PEÇAS E CONVERSÕES ---
    _pecas.clear();
    _conversoes.clear();

    final agora = DateTime.now();

    void registrar({
      required String id,
      required VeiculoModel veiculo,
      required String descricao,
      required CategoriaPeca categoria,
      required String codigoOem,
      required String posicao,
      String eixo = 'Dianteiro',
      String lado = 'Ambos os lados (Direito/Esquerdo)',
      required List<CodigoEquivalenteItem> equivalentes,
      String obs = '',
      bool isFavorito = false,
    }) {
      final peca = PecaModel(
        id: 'peca_$id',
        descricao: descricao,
        categoria: categoria,
        codigoOem: codigoOem,
        montadoraOrigem: veiculo.montadora,
        posicao: posicao,
        eixo: eixo,
        lado: lado,
        observacoesTecnicas: obs,
      );
      _pecas.add(peca);

      final conversao = ConversaoModel(
        id: 'conv_$id',
        peca: peca,
        veiculo: veiculo,
        equivalentes: equivalentes,
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: obs.isNotEmpty ? obs : 'Conversão 100% testada e homologada no balcão.',
        usuarioAtualizacao: 'Engenharia Silva',
        dataAtualizacao: agora,
        isFavorito: isFavorito,
      );
      _conversoes.add(conversao);
    }

    // === 1. TOYOTA COROLLA G12 ===
    registrar(
      id: 'corolla_amort_diant',
      veiculo: vCorolla2020,
      descricao: 'Amortecedor Dianteiro Pressurizado (Par)',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '48510-02880 / 48520-02880',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33256', linha: 'Turbogás Pressurizado'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742084SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33256', linha: 'Pressurizado'),
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '339432', linha: 'Excel-G'),
      ],
      obs: 'Fixação específica da barra estabilizadora da suspensão TNGA.',
      isFavorito: true,
    );

    registrar(
      id: 'corolla_amort_tras',
      veiculo: vCorolla2020,
      descricao: 'Amortecedor Traseiro Multilink',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '48530-02E90',
      posicao: 'Traseiro Direito/Esquerdo',
      eixo: 'Traseiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GB27643', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '378135SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '349085', linha: 'Excel-G'),
      ],
      obs: 'Exclusivo para geração G12 com suspensão independente traseira multilink.',
    );

    registrar(
      id: 'corolla_pastilha_diant',
      veiculo: vCorolla2020,
      descricao: 'Jogo de Pastilhas de Freio Dianteiro (Cerâmica)',
      categoria: CategoriaPeca.freios,
      codigoOem: '04465-02400 / 04465-12610',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1544', linha: 'Ceramic Line'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-1784', linha: 'Cerâmica'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0745', linha: 'QuietCast'),
        const CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT14640', linha: 'D-Tec'),
      ],
      obs: 'Com chapas anti-ruído (shim) e clips de retorno inclusos.',
      isFavorito: true,
    );

    registrar(
      id: 'corolla_filtro_oleo',
      veiculo: vCorolla2020,
      descricao: 'Elemento Filtro de Óleo do Motor 2.0',
      categoria: CategoriaPeca.motor,
      codigoOem: '04152-YZZA6 / 04152-37010',
      posicao: 'Compartimento do Motor',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'MANN-FILTER', codigo: 'HU6006z', linha: 'Ecoline'),
        const CodigoEquivalenteItem(fabricanteNome: 'MAHLE', codigo: 'OX416D1', linha: 'Eco'),
        const CodigoEquivalenteItem(fabricanteNome: 'FRAM', codigo: 'CH10358ECO', linha: 'Extra Guard'),
        const CodigoEquivalenteItem(fabricanteNome: 'TECFIL', codigo: 'PEL725', linha: 'Refil Ecológico'),
      ],
      obs: 'Acompanha anel O-ring de vedação da carcaça e adaptador de drenagem.',
    );

    // === 2. TOYOTA HILUX 2.8 DIESEL ===
    registrar(
      id: 'hilux_amort_diant',
      veiculo: vHilux2016,
      descricao: 'Amortecedor Dianteiro Heavy Duty 4x4',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '48510-0K300 / 48510-09V30',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33303', linha: 'Turbogás 4x4'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: 'D8024', linha: 'Adventure 4x4'),
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '341398', linha: 'Skorched4s Reforçado'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33303', linha: 'Pressurizado Heavy Duty'),
      ],
      obs: 'Corpo reforçado para aplicação off-road e carga pesada.',
      isFavorito: true,
    );

    // === 3. VOLKSWAGEN GOL G6/G7 ===
    registrar(
      id: 'gol_amort_diant',
      veiculo: vGolG6,
      descricao: 'Amortecedor Dianteiro Turbogás Pressurizado',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '5U0413031 / 5U0413031C',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP32478', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: 'SP037', linha: 'Monro-Matic Plus'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG31145', linha: 'Pressurizado'),
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '333753', linha: 'Excel-G'),
      ],
      obs: 'Compatível com toda a linha Gol G5, G6, G7 e Voyage.',
      isFavorito: true,
    );

    registrar(
      id: 'gol_pastilha_diant',
      veiculo: vGolG6,
      descricao: 'Jogo de Pastilha de Freio Dianteira Sistema Teves',
      categoria: CategoriaPeca.freios,
      codigoOem: '5Z0698151A / 5U0698151',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0230', linha: 'Original Quality'),
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/362', linha: 'Lonaflex'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-250', linha: 'Original'),
        const CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT02650', linha: 'Standard'),
      ],
      obs: 'Verificar se o veículo utiliza sistema de freio Teves (com mola superior) ou Varga.',
      isFavorito: true,
    );

    // === 4. VOLKSWAGEN POLO / T-CROSS MQB ===
    registrar(
      id: 'polo_amort_diant',
      veiculo: vPoloMQB,
      descricao: 'Amortecedor Dianteiro Pressurizado Plataforma MQB',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '2Q0413031 / 2G0413031',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33355', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742195SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33355', linha: 'Pressurizado'),
      ],
      obs: 'Específico para manga de eixo de 50mm da plataforma MQB-A0.',
    );

    registrar(
      id: 'polo_pastilha_diant',
      veiculo: vPoloMQB,
      descricao: 'Pastilha de Freio Dianteira com Sensor MQB',
      categoria: CategoriaPeca.freios,
      codigoOem: '2Q0698151 / 2G0698151',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1512', linha: 'Ceramic'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0980', linha: 'Premium'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-1778', linha: 'Cerâmica'),
      ],
      obs: 'Conector elétrico do sensor de aviso de desgaste no painel incluso.',
    );

    // === 5. CHEVROLET ONIX / TRACKER ===
    registrar(
      id: 'onix_amort_diant',
      veiculo: vOnix2019,
      descricao: 'Amortecedor Dianteiro Turbogás Nova Geração GEM',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '26245362 / 26245363',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33342', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742210SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33342', linha: 'Pressurizado'),
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3330085', linha: 'Excel-G'),
      ],
      obs: 'Aplicável tanto no Onix Hatch quanto no Onix Plus Sedan 1.0 Turbo e Aspirado.',
      isFavorito: true,
    );

    registrar(
      id: 'onix_pastilha_diant',
      veiculo: vOnix2019,
      descricao: 'Jogo de Pastilhas de Freio Dianteiro Cerâmica',
      categoria: CategoriaPeca.freios,
      codigoOem: '26244439 / 26296187',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1535', linha: 'Ceramic'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0921', linha: 'QuietCast'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-1780', linha: 'Cerâmica'),
        const CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT15120', linha: 'D-Tec'),
      ],
      obs: 'Compatível com aro 15 e aro 16 de fábrica.',
      isFavorito: true,
    );

    registrar(
      id: 'onix_filtro_oleo',
      veiculo: vOnix2019,
      descricao: 'Filtro de Óleo Blindado Motor 1.0 3 Cilindros Turbo',
      categoria: CategoriaPeca.motor,
      codigoOem: '55509193 / 12696048',
      posicao: 'Compartimento do Motor',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'MANN-FILTER', codigo: 'W7056', linha: 'Spin-on'),
        const CodigoEquivalenteItem(fabricanteNome: 'MAHLE', codigo: 'OC1566', linha: 'Micro-star'),
        const CodigoEquivalenteItem(fabricanteNome: 'TECFIL', codigo: 'PSL619', linha: 'Blindado'),
        const CodigoEquivalenteItem(fabricanteNome: 'FRAM', codigo: 'PH12460', linha: 'Extra Guard'),
      ],
      obs: 'Atenção técnica: utilizar óleo homologado GM Dexos1 Gen3 para preservação da correia banhada.',
    );

    // === 6. FIAT STRADA / ARGO / TORO ===
    registrar(
      id: 'strada_amort_diant',
      veiculo: vStrada2020,
      descricao: 'Amortecedor Dianteiro Turbogás Nova Strada',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '52144218 / 52144219',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33360', linha: 'Turbogás Reforçado'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742215SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33360', linha: 'Pressurizado'),
      ],
      obs: 'Curso de haste estendido para a suspensão elevada da cabine dupla e simples.',
      isFavorito: true,
    );

    registrar(
      id: 'strada_pastilha_diant',
      veiculo: vStrada2020,
      descricao: 'Jogo de Pastilhas de Freio Dianteiro 1.3 Firefly',
      categoria: CategoriaPeca.freios,
      codigoOem: '7091963 / 77367800',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-2094', linha: 'Original'),
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1518', linha: 'Advanced'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0968', linha: 'Standard'),
      ],
      obs: 'Compatível com sistema de pinça Continental/Ate.',
    );

    registrar(
      id: 'toro_amort_diant',
      veiculo: vToro2016,
      descricao: 'Amortecedor Dianteiro Pressurizado Toro 4x2 e 4x4',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '52033838 / 52033839',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33290', linha: 'Turbogás Heavy Duty'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742180SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33290', linha: 'Pressurizado'),
      ],
      obs: 'Idêntico em fixação ao Jeep Renegade e Jeep Compass.',
      isFavorito: true,
    );

    // === 7. HYUNDAI HB20 / CRETA ===
    registrar(
      id: 'hb20_amort_diant',
      veiculo: vHB202019,
      descricao: 'Amortecedor Dianteiro Pressurizado Novo HB20',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '54650-1S000 / 54660-1S000',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3330058 / 3330059', linha: 'Excel-G'),
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33298', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742150SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33298', linha: 'Pressurizado'),
      ],
      obs: 'Atenção na montagem do prato superior da mola para evitar ruídos de esterçamento.',
      isFavorito: true,
    );

    registrar(
      id: 'hb20_pastilha_diant',
      veiculo: vHB202019,
      descricao: 'Jogo de Pastilhas de Freio Dianteiro Sistema Mando',
      categoria: CategoriaPeca.freios,
      codigoOem: '58101-1SA00 / 58101-B1A00',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1360', linha: 'Ceramic'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-1288', linha: 'Cerâmica'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0872', linha: 'QuietCast'),
        const CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT13880', linha: 'D-Tec'),
      ],
      obs: 'Sistema de pinça Mando original de fábrica.',
      isFavorito: true,
    );

    // === 8. JEEP RENEGADE / COMPASS ===
    registrar(
      id: 'renegade_amort_diant',
      veiculo: vRenegade2015,
      descricao: 'Amortecedor Dianteiro Pressurizado SUV 4x2/4x4',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '51965900 / 51965901',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33285', linha: 'Turbogás SUV'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742175SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33285', linha: 'Pressurizado'),
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3340158', linha: 'Excel-G'),
      ],
      obs: 'Mesma plataforma técnica da Fiat Toro.',
      isFavorito: true,
    );

    registrar(
      id: 'compass_pastilha_diant',
      veiculo: vCompass2017,
      descricao: 'Jogo de Pastilhas de Freio Dianteiras Cerâmica 1.3T / 2.0D',
      categoria: CategoriaPeca.freios,
      codigoOem: '77367735 / 68258382AA',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1510', linha: 'Ceramic Premium'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0955', linha: 'QuietCast Ceramic'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-2080', linha: 'Cerâmica'),
        const CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT15040', linha: 'D-Tec'),
      ],
      obs: 'Para discos dianteiros de 305mm.',
      isFavorito: true,
    );

    // === 9. RENAULT KWID / SANDERO / DUSTER ===
    registrar(
      id: 'kwid_amort_diant',
      veiculo: vKwid2017,
      descricao: 'Amortecedor Dianteiro Turbogás Kwid 1.0 SCe',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '543026857R / 543027204R',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33330', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742200SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33330', linha: 'Pressurizado'),
      ],
      obs: 'Fixação exclusiva de 3 parafusos de cubo.',
      isFavorito: true,
    );

    registrar(
      id: 'kwid_pastilha_diant',
      veiculo: vKwid2017,
      descricao: 'Jogo de Pastilhas de Freio Dianteiro Kwid',
      categoria: CategoriaPeca.freios,
      codigoOem: '410605536R / 410609647R',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1505', linha: 'Ceramic'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-2070', linha: 'Original'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0935', linha: 'Quality'),
      ],
      obs: 'Atenção aos modelos pós-2022 que receberam disco ventilado de maior espessura.',
    );

    registrar(
      id: 'duster_amort_diant',
      veiculo: vDuster2015,
      descricao: 'Amortecedor Dianteiro Duster 4x2 e 4x4',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '543028126R / 543020011R',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33270', linha: 'Turbogás SUV'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742135SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33270', linha: 'Pressurizado'),
      ],
      obs: 'Compatível com Duster Oroch e Renault Captur.',
    );

    // === 10. HONDA CIVIC G10 / HR-V / FIT ===
    registrar(
      id: 'civic_amort_diant',
      veiculo: vCivicG10,
      descricao: 'Amortecedor Dianteiro Pressurizado Civic G10',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '51611-TBA-A01 / 51621-TBA-A01',
      posicao: 'Dianteiro Direito/Esquerdo',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3340172 / 3340173', linha: 'Excel-G Premium'),
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33315', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742190SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33315', linha: 'Pressurizado'),
      ],
      obs: 'Fixação hidráulica superior. Não intercambiável com a geração G9.',
      isFavorito: true,
    );

    registrar(
      id: 'civic_pastilha_diant',
      veiculo: vCivicG10,
      descricao: 'Jogo de Pastilhas de Freio Dianteiro Cerâmica Civic G10',
      categoria: CategoriaPeca.freios,
      codigoOem: '45022-TBA-A00 / 45022-TET-H00',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1522', linha: 'Ceramic'),
        const CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-1768', linha: 'Cerâmica'),
        const CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0940', linha: 'QuietCast'),
        const CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT14920', linha: 'D-Tec'),
      ],
      obs: 'Acompanha jogo de travas e molas expansoras anti-ruído originais.',
      isFavorito: true,
    );

    registrar(
      id: 'hrv_amort_diant',
      veiculo: vHRV2015,
      descricao: 'Amortecedor Dianteiro Pressurizado HR-V',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '51611-T7A-M01 / 51621-T7A-M01',
      posicao: 'Dianteiro',
      equivalentes: [
        const CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3340165 / 3340166', linha: 'Excel-G'),
        const CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33310', linha: 'Turbogás'),
        const CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742185SP', linha: 'OESpectrum'),
        const CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33310', linha: 'Pressurizado'),
      ],
      obs: 'Válvula de amortecimento adaptativa desenvolvida especificamente para SUV compacto.',
    );
  }
}
