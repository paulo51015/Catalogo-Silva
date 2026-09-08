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
    final savedConversoes = prefs.getString('silva_conversoes_data');

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
    final index = _conversoes.indexWhere((c) => c.id == conversao.id);
    if (index != -1) {
      _conversoes[index] = conversao;
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
    final index = _conversoes.indexWhere((c) => c.id == id);
    if (index != -1) {
      final current = _conversoes[index];
      _conversoes[index] = current.copyWith(isFavorito: !current.isFavorito);
      await _salvarNoStorage();
      notifyListeners();
    }
  }

  // --- PERSISTÊNCIA ---

  Future<void> _salvarNoStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final convJson = jsonEncode(_conversoes.map((c) => c.toMap()).toList());
      final veicJson = jsonEncode(_veiculos.map((v) => v.toMap()).toList());
      final pecaJson = jsonEncode(_pecas.map((p) => p.toMap()).toList());
      final fabJson = jsonEncode(_fabricantes.map((f) => f.toMap()).toList());

      await prefs.setString('silva_conversoes_data', convJson);
      await prefs.setString('silva_veiculos_data', veicJson);
      await prefs.setString('silva_pecas_data', pecaJson);
      await prefs.setString('silva_fabricantes_data', fabJson);
    } catch (e) {
      debugPrint('Erro ao salvar no storage: $e');
    }
  }

  void _carregarDoStorage(SharedPreferences prefs) {
    final convStr = prefs.getString('silva_conversoes_data');
    final veicStr = prefs.getString('silva_veiculos_data');
    final pecaStr = prefs.getString('silva_pecas_data');
    final fabStr = prefs.getString('silva_fabricantes_data');

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

  // --- POPULAÇÃO DA BASE AUTOMOTIVA OFICIAL ---

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
      const FabricanteModel(id: 'fab_ngk', nome: 'NGK', paisOrigem: 'Japão'),
      const FabricanteModel(id: 'fab_skf', nome: 'SKF', paisOrigem: 'Suécia'),
      const FabricanteModel(id: 'fab_luk', nome: 'LUK', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_sachs', nome: 'SACHS', paisOrigem: 'Alemanha'),
      const FabricanteModel(id: 'fab_sabo', nome: 'SABÓ', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_axios', nome: 'AXIOS', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_controil', nome: 'CONTROIL', paisOrigem: 'Brasil'),
      const FabricanteModel(id: 'fab_valeo', nome: 'VALEO', paisOrigem: 'França'),
    ]);

    // Veículos mais atendidos no balcão
    final vCorolla2020 = const VeiculoModel(
      id: 'v_corolla_2020',
      montadora: 'Toyota',
      modelo: 'Corolla',
      versao: 'GLI / XEI / Altis',
      anoInicio: 2020,
      anoFim: 2024,
      motor: '2.0 16V Dynamic Force',
      combustivel: 'Flex',
      cilindrada: '1987 cc',
      observacoes: 'Geração G12 com suspensão traseira multilink',
    );

    final vGolG6 = const VeiculoModel(
      id: 'v_gol_g6',
      montadora: 'Volkswagen',
      modelo: 'Gol',
      versao: 'Trendline / Comfortline',
      anoInicio: 2013,
      anoFim: 2023,
      motor: '1.6 8V EA111 / 1.0 12V EA211',
      combustivel: 'Flex',
      cilindrada: '1598 cc',
      observacoes: 'Plataforma PQ24 / G6 e G7',
    );

    final vOnix2019 = const VeiculoModel(
      id: 'v_onix_2019',
      montadora: 'Chevrolet',
      modelo: 'Onix',
      versao: 'LT / LTZ / Premier',
      anoInicio: 2019,
      anoFim: 2024,
      motor: '1.0 12V 3 Cil Turbo e Aspirado',
      combustivel: 'Flex',
      cilindrada: '999 cc',
      observacoes: 'Nova geração plataforma GEM',
    );

    final vStrada2020 = const VeiculoModel(
      id: 'v_strada_2020',
      montadora: 'Fiat',
      modelo: 'Strada',
      versao: 'Endurance / Freedom / Volcano',
      anoInicio: 2020,
      anoFim: 2024,
      motor: '1.3 8V Firefly / 1.4 Fire',
      combustivel: 'Flex',
      cilindrada: '1332 cc',
      observacoes: 'Nova geração cabine dupla e plus',
    );

    final vHB20 = const VeiculoModel(
      id: 'v_hb20_2019',
      montadora: 'Hyundai',
      modelo: 'HB20',
      versao: 'Sense / Vision / Diamond',
      anoInicio: 2019,
      anoFim: 2024,
      motor: '1.0 12V Kappa / 1.0 Turbo TGDI',
      combustivel: 'Flex',
      cilindrada: '998 cc',
      observacoes: 'Segunda geração com nova calibração de suspensão',
    );

    final vCompass = const VeiculoModel(
      id: 'v_compass_2017',
      montadora: 'Jeep',
      modelo: 'Compass',
      versao: 'Sport / Longitude / Limited',
      anoInicio: 2017,
      anoFim: 2024,
      motor: '2.0 Tigershark / 1.3 Turbo T270',
      combustivel: 'Flex',
      cilindrada: '1995 cc',
      observacoes: 'SUV Médio tração 4x2 e 4x4',
    );

    final vCivicG10 = const VeiculoModel(
      id: 'v_civic_g10',
      montadora: 'Honda',
      modelo: 'Civic',
      versao: 'EX / EXL / Touring',
      anoInicio: 2017,
      anoFim: 2022,
      motor: '2.0 i-VTEC / 1.5 Turbo',
      combustivel: 'Flex / Gasolina',
      cilindrada: '1996 cc',
      observacoes: 'Geração 10 com suspensão independente',
    );

    _veiculos.clear();
    _veiculos.addAll([
      vCorolla2020,
      vGolG6,
      vOnix2019,
      vStrada2020,
      vHB20,
      vCompass,
      vCivicG10,
    ]);

    // Peças
    final pAmortCorollaD = const PecaModel(
      id: 'p_amort_corolla_d',
      descricao: 'Amortecedor Dianteiro',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '48510-02880',
      montadoraOrigem: 'Toyota',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos (Par)',
      observacoesTecnicas: 'Pressurizado a gás (Turbogás). Recomenda-se trocar os batentes e coifas juntos.',
    );

    final pAmortCorollaT = const PecaModel(
      id: 'p_amort_corolla_t',
      descricao: 'Amortecedor Traseiro',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '48530-02550',
      montadoraOrigem: 'Toyota',
      posicao: 'Traseiro',
      eixo: 'Traseiro',
      lado: 'Ambos (Par)',
      observacoesTecnicas: 'Fixação olhal inferior e pino superior.',
    );

    final pPastilhaCorolla = const PecaModel(
      id: 'p_past_corolla_d',
      descricao: 'Jogo de Pastilhas de Freio Dianteira',
      categoria: CategoriaPeca.freios,
      codigoOem: '04465-02400',
      montadoraOrigem: 'Toyota',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Sistema Akebono com sensor acústico de desgaste.',
    );

    final pFiltroOleoCorolla = const PecaModel(
      id: 'p_filtro_corolla',
      descricao: 'Filtro de Óleo do Motor (Elemento Refil)',
      categoria: CategoriaPeca.filtros,
      codigoOem: '04152-YZZA6',
      montadoraOrigem: 'Toyota',
      posicao: 'Motor',
      eixo: 'Central',
      observacoesTecnicas: 'Acompanha anel O-ring de vedação.',
    );

    final pAmortGolD = const PecaModel(
      id: 'p_amort_gol_d',
      descricao: 'Amortecedor Dianteiro',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '5U0413031',
      montadoraOrigem: 'Volkswagen',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Estrutural McPherson. Compatível com Gol, Voyage e Saveiro G5/G6/G7.',
    );

    final pAmortGolT = const PecaModel(
      id: 'p_amort_gol_t',
      descricao: 'Amortecedor Traseiro',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '5U0513025',
      montadoraOrigem: 'Volkswagen',
      posicao: 'Traseiro',
      eixo: 'Traseiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Fixação padrão VW.',
    );

    final pPastilhaGol = const PecaModel(
      id: 'p_past_gol_d',
      descricao: 'Jogo de Pastilha de Freio Dianteira',
      categoria: CategoriaPeca.freios,
      codigoOem: '5Z0698151A',
      montadoraOrigem: 'Volkswagen',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Sistema Teves / ATE aro 14 e 15.',
    );

    final pAmortOnixD = const PecaModel(
      id: 'p_amort_onix_d',
      descricao: 'Amortecedor Dianteiro',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '26245362',
      montadoraOrigem: 'Chevrolet',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Novo Onix modelo 2019 em diante.',
    );

    final pFiltroOleoOnix = const PecaModel(
      id: 'p_filtro_onix',
      descricao: 'Filtro de Óleo Blindado',
      categoria: CategoriaPeca.filtros,
      codigoOem: '55594651',
      montadoraOrigem: 'Chevrolet',
      posicao: 'Motor',
      eixo: 'Central',
      observacoesTecnicas: 'Rosca M20x1.5 com válvula anti-retorno.',
    );

    final pAmortStradaD = const PecaModel(
      id: 'p_amort_strada_d',
      descricao: 'Amortecedor Dianteiro Reforçado',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '52144788',
      montadoraOrigem: 'Fiat',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Calibração específica para carga Nova Strada.',
    );

    final pAmortHB20D = const PecaModel(
      id: 'p_amort_hb20_d',
      descricao: 'Amortecedor Dianteiro',
      categoria: CategoriaPeca.suspensao,
      codigoOem: '54650-1S000',
      montadoraOrigem: 'Hyundai',
      posicao: 'Dianteiro',
      eixo: 'Dianteiro',
      lado: 'Ambos',
      observacoesTecnicas: 'Pressurizado a gás. Haste 20mm.',
    );

    _pecas.clear();
    _pecas.addAll([
      pAmortCorollaD,
      pAmortCorollaT,
      pPastilhaCorolla,
      pFiltroOleoCorolla,
      pAmortGolD,
      pAmortGolT,
      pPastilhaGol,
      pAmortOnixD,
      pFiltroOleoOnix,
      pAmortStradaD,
      pAmortHB20D,
    ]);

    // Conversões Oficiais Confirmadas
    final now = DateTime.now();

    _conversoes.clear();
    _conversoes.addAll([
      // 1. Toyota Corolla - Amortecedor Dianteiro
      ConversaoModel(
        id: 'conv_corolla_amort_d',
        peca: pAmortCorollaD,
        veiculo: vCorolla2020,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33256', linha: 'Turbogás'),
          CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742084SP', linha: 'OESpectrum'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG41235', linha: 'Pressurizado'),
          CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3340156', linha: 'Excel-G'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Aplicação 100% confirmada para Corolla G12 Motor 2.0 Dynamic Force anos 2020 a 2024.',
        usuarioAtualizacao: 'Administrador (Catálogo Oficial)',
        dataAtualizacao: now,
        isFavorito: true, // Marcado como favorito por padrão
      ),

      // 2. Toyota Corolla - Amortecedor Traseiro
      ConversaoModel(
        id: 'conv_corolla_amort_t',
        peca: pAmortCorollaT,
        veiculo: vCorolla2020,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GB27542', linha: 'Turbogás'),
          CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '378045SP', linha: 'OESpectrum'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG33098', linha: 'Pressurizado'),
          CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3410088', linha: 'Excel-G'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Suspensão traseira independente multilink.',
        usuarioAtualizacao: 'Administrador (Catálogo Oficial)',
        dataAtualizacao: now,
        isFavorito: true,
      ),

      // 3. Toyota Corolla - Pastilhas de Freio
      ConversaoModel(
        id: 'conv_corolla_pastilha',
        peca: pPastilhaCorolla,
        veiculo: vCorolla2020,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/1544', linha: 'Cerâmica'),
          CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0921', linha: 'Euroline'),
          CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT14520', linha: 'Varga'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'NKF1288P', linha: 'Standard'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Freio a disco ventilado dianteiro.',
        usuarioAtualizacao: 'Administrador',
        dataAtualizacao: now,
        isFavorito: true,
      ),

      // 4. Toyota Corolla - Filtro de Óleo
      ConversaoModel(
        id: 'conv_corolla_filtro',
        peca: pFiltroOleoCorolla,
        veiculo: vCorolla2020,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'MAHLE', codigo: 'OX416D1', linha: 'Elemento Ecológico'),
          CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986B00016', linha: 'Filtro de Óleo'),
          CodigoEquivalenteItem(fabricanteNome: 'FRAM', codigo: 'CH10358', linha: 'Eco'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Substituição recomendada a cada troca de óleo 0W20.',
        usuarioAtualizacao: 'Administrador',
        dataAtualizacao: now,
      ),

      // 5. VW Gol G6 - Amortecedor Dianteiro
      ConversaoModel(
        id: 'conv_gol_amort_d',
        peca: pAmortGolD,
        veiculo: vGolG6,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP32478', linha: 'Turbogás'),
          CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: 'SP038', linha: 'Monro-Matic'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG31145', linha: 'Pressurizado'),
          CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '333742', linha: 'Excel-G'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Compatível com toda a linha Gol/Voyage/Saveiro G5, G6, G7 e G8.',
        usuarioAtualizacao: 'Administrador (Catálogo Oficial)',
        dataAtualizacao: now,
        isFavorito: true,
      ),

      // 6. VW Gol G6 - Pastilha de Freio
      ConversaoModel(
        id: 'conv_gol_pastilha',
        peca: pPastilhaGol,
        veiculo: vGolG6,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'FRAS-LE', codigo: 'PD/58', linha: 'Standard'),
          CodigoEquivalenteItem(fabricanteNome: 'BOSCH', codigo: '0986BB0230', linha: 'Frenagem Segura'),
          CodigoEquivalenteItem(fabricanteNome: 'TRW', codigo: 'RCPT02670', linha: 'Varga'),
          CodigoEquivalenteItem(fabricanteNome: 'COBREQ', codigo: 'N-250', linha: 'Metálica'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Sistema Teves ATE.',
        usuarioAtualizacao: 'Administrador',
        dataAtualizacao: now,
        isFavorito: true,
      ),

      // 7. Chevrolet Onix 2019+ - Amortecedor Dianteiro
      ConversaoModel(
        id: 'conv_onix_amort_d',
        peca: pAmortOnixD,
        veiculo: vOnix2019,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33342', linha: 'Turbogás'),
          CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '749021SP', linha: 'OESpectrum'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG41310', linha: 'Pressurizado'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Exclusivo para o Novo Onix / Onix Plus (Geracao 2) a partir de 2019.',
        usuarioAtualizacao: 'Administrador',
        dataAtualizacao: now,
        isFavorito: true,
      ),

      // 8. Fiat Strada 2020+ - Amortecedor Dianteiro
      ConversaoModel(
        id: 'conv_strada_amort_d',
        peca: pAmortStradaD,
        veiculo: vStrada2020,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33310', linha: 'Turbogás Reforçado'),
          CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '749015SP', linha: 'OESpectrum'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG41285', linha: 'Heavy Duty'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'Nova Strada cabine simples e dupla. Haste e prato reforçados.',
        usuarioAtualizacao: 'Administrador',
        dataAtualizacao: now,
      ),

      // 9. Hyundai HB20 - Amortecedor Dianteiro
      ConversaoModel(
        id: 'conv_hb20_amort_d',
        peca: pAmortHB20D,
        veiculo: vHB20,
        equivalentes: const [
          CodigoEquivalenteItem(fabricanteNome: 'COFAP', codigo: 'GP33180', linha: 'Turbogás'),
          CodigoEquivalenteItem(fabricanteNome: 'MONROE', codigo: '742045SP', linha: 'OESpectrum'),
          CodigoEquivalenteItem(fabricanteNome: 'NAKATA', codigo: 'HG41190', linha: 'Pressurizado'),
          CodigoEquivalenteItem(fabricanteNome: 'KYB', codigo: '3330058', linha: 'Excel-G'),
        ],
        status: StatusConfiabilidade.confirmada,
        fonte: FonteConversao.catalogoFabricante,
        observacaoCompatibilidade: 'HB20 Hatch e HB20S Sedan.',
        usuarioAtualizacao: 'Administrador',
        dataAtualizacao: now,
        isFavorito: true,
      ),
    ]);
  }
}
