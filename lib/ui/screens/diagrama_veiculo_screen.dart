import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../models/veiculo_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/diagrama_hotspot_widget.dart';
import 'conversao_detail_screen.dart';

class DiagramaVeiculoScreen extends StatefulWidget {
  final DatabaseService db;

  const DiagramaVeiculoScreen({
    super.key,
    required this.db,
  });

  @override
  State<DiagramaVeiculoScreen> createState() => _DiagramaVeiculoScreenState();
}

class _DiagramaVeiculoScreenState extends State<DiagramaVeiculoScreen> {
  late VeiculoModel _veiculoSelecionado;
  String _sistemaAtivo = 'Suspensão & Chassi';
  HotspotItem? _hotspotSelecionado;

  final List<String> _sistemas = [
    'Suspensão & Chassi',
    'Sistema de Freios',
    'Motor & Filtros',
    'Transmissão & Direção',
  ];

  @override
  void initState() {
    super.initState();
    _veiculoSelecionado = widget.db.veiculos.isNotEmpty
        ? widget.db.veiculos.first
        : const VeiculoModel(
            id: 'v_padrao',
            montadora: 'Toyota',
            modelo: 'Corolla',
            versao: 'GLI / XEI',
            anoInicio: 2020,
            anoFim: 2025,
            motor: '2.0 16V',
            combustivel: 'Flex',
            cilindrada: '1987 cc',
          );
  }

  List<HotspotItem> _gerarHotspotsParaSistema() {
    final conversoesVeiculo = widget.db.conversoes.where((c) => c.veiculo.id == _veiculoSelecionado.id).toList();

    ConversaoModel? encontrar(String termo) {
      final t = termo.toLowerCase();
      try {
        return conversoesVeiculo.firstWhere(
          (c) => c.peca.descricao.toLowerCase().contains(t) || c.peca.codigoOem.toLowerCase().contains(t),
        );
      } catch (_) {
        return null;
      }
    }

    if (_sistemaAtivo == 'Suspensão & Chassi') {
      final amortDiant = encontrar('amortecedor dianteiro') ?? encontrar('amortecedor');
      final amortTras = encontrar('amortecedor traseiro');

      return [
        HotspotItem(
          id: 'amort_diant_esq',
          titulo: 'Amortecedor Dianteiro Esquerdo',
          categoria: 'Suspensão',
          topPercent: 0.22,
          leftPercent: 0.18,
          codigoOem: amortDiant?.peca.codigoOem ?? '48520-02880',
          equivalentes: amortDiant?.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').toList() ??
              ['COFAP: GP33256', 'MONROE: 742084SP', 'NAKATA: HG33256'],
          observacao: 'Verificar estado do kit coifa e batente superior.',
          conversaoRef: amortDiant,
        ),
        HotspotItem(
          id: 'amort_diant_dir',
          titulo: 'Amortecedor Dianteiro Direito',
          categoria: 'Suspensão',
          topPercent: 0.22,
          leftPercent: 0.76,
          codigoOem: amortDiant?.peca.codigoOem ?? '48510-02880',
          equivalentes: amortDiant?.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').toList() ??
              ['COFAP: GP33256', 'MONROE: 742084SP', 'NAKATA: HG33256'],
          observacao: 'Fixação da bieleta da barra estabilizadora.',
          conversaoRef: amortDiant,
        ),
        HotspotItem(
          id: 'bieleta_diant',
          titulo: 'Bieleta da Barra Estabilizadora Dianteira',
          categoria: 'Suspensão / Direção',
          topPercent: 0.32,
          leftPercent: 0.28,
          codigoOem: '48820-47030',
          equivalentes: const ['NAKATA: N99245', 'COFAP: BTC08115', 'VIEMAR: 318042'],
          observacao: 'Pivôs esféricos de alta durabilidade com vedação reforçada.',
        ),
        HotspotItem(
          id: 'pivo_suspensao',
          titulo: 'Pivô de Suspensão Inferior',
          categoria: 'Suspensão',
          topPercent: 0.32,
          leftPercent: 0.68,
          codigoOem: '43330-02130',
          equivalentes: const ['VIEMAR: 503254', 'NAKATA: N99120', 'TRW: PS4920'],
          observacao: 'Encaixe cônico na manga de eixo.',
        ),
        HotspotItem(
          id: 'amort_tras_esq',
          titulo: 'Amortecedor Traseiro Esquerdo',
          categoria: 'Suspensão',
          topPercent: 0.72,
          leftPercent: 0.18,
          codigoOem: amortTras?.peca.codigoOem ?? '48530-02E90',
          equivalentes: amortTras?.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').toList() ??
              ['COFAP: GB27643', 'MONROE: 378135SP', 'KYB: 349085'],
          observacao: 'Suspensão traseira independente multilink.',
          conversaoRef: amortTras,
        ),
        HotspotItem(
          id: 'amort_tras_dir',
          titulo: 'Amortecedor Traseiro Direito',
          categoria: 'Suspensão',
          topPercent: 0.72,
          leftPercent: 0.76,
          codigoOem: amortTras?.peca.codigoOem ?? '48530-02E90',
          equivalentes: amortTras?.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').toList() ??
              ['COFAP: GB27643', 'MONROE: 378135SP', 'KYB: 349085'],
          observacao: 'Suspensão traseira independente multilink.',
          conversaoRef: amortTras,
        ),
      ];
    } else if (_sistemaAtivo == 'Sistema de Freios') {
      final pastilhaDiant = encontrar('pastilha de freio') ?? encontrar('pastilha');

      return [
        HotspotItem(
          id: 'disco_freio_diant_esq',
          titulo: 'Disco de Freio Dianteiro Ventilado (Esq)',
          categoria: 'Freios',
          topPercent: 0.20,
          leftPercent: 0.14,
          codigoOem: '43512-02330',
          equivalentes: const ['FREMAX: BD-4351', 'HIPPER FREIOS: HF66', 'TRW: RCDI08540', 'BOSCH: 0986BB4512'],
          observacao: 'Diâmetro externo 277mm com canais de ventilação.',
        ),
        HotspotItem(
          id: 'pastilha_freio_diant',
          titulo: 'Jogo de Pastilhas Dianteiras Cerâmica',
          categoria: 'Freios',
          topPercent: 0.20,
          leftPercent: 0.80,
          codigoOem: pastilhaDiant?.peca.codigoOem ?? '04465-02400',
          equivalentes: pastilhaDiant?.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').toList() ??
              ['FRAS-LE: PD/1544', 'COBREQ: N-1784', 'BOSCH: 0986BB0745', 'TRW: RCPT14640'],
          observacao: 'Composição cerâmica anti-ruído com plaquetas de apoio.',
          conversaoRef: pastilhaDiant,
        ),
        HotspotItem(
          id: 'cilindro_mestre',
          titulo: 'Cilindro Mestre Duplo com Reservatório',
          categoria: 'Freios / Hidráulica',
          topPercent: 0.35,
          leftPercent: 0.38,
          codigoOem: '47201-02680',
          equivalentes: const ['CONTROIL: C-2184', 'TRW: PMK780', 'BOSCH: 0986BB7890'],
          observacao: 'Compatível com sistema ABS / ESP e assistência de frenagem de emergência.',
        ),
        HotspotItem(
          id: 'disco_freio_tras',
          titulo: 'Disco de Freio Traseiro Sólido (Par)',
          categoria: 'Freios',
          topPercent: 0.74,
          leftPercent: 0.14,
          codigoOem: '42431-02210',
          equivalentes: const ['FREMAX: BD-4243', 'HIPPER FREIOS: HF67', 'TRW: RCDI08550'],
          observacao: 'Disco sólido traseiro de 270mm com tambor de freio de mão interno.',
        ),
        HotspotItem(
          id: 'pastilha_freio_tras',
          titulo: 'Jogo de Pastilhas Traseiras',
          categoria: 'Freios',
          topPercent: 0.74,
          leftPercent: 0.80,
          codigoOem: '04466-02380',
          equivalentes: const ['FRAS-LE: PD/1545', 'COBREQ: N-1785', 'BOSCH: 0986BB0746'],
          observacao: 'Compatível com acionamento elétrico de freio de estacionamento (EPB).',
        ),
      ];
    } else if (_sistemaAtivo == 'Motor & Filtros') {
      final filtroOleo = encontrar('filtro de óleo') ?? encontrar('filtro');

      return [
        HotspotItem(
          id: 'filtro_oleo',
          titulo: 'Filtro de Óleo do Motor (Refil Ecológico)',
          categoria: 'Motor',
          topPercent: 0.22,
          leftPercent: 0.44,
          codigoOem: filtroOleo?.peca.codigoOem ?? '04152-YZZA6',
          equivalentes: filtroOleo?.equivalentes.map((e) => '${e.fabricanteNome}: ${e.codigo}').toList() ??
              ['MANN: HU6006z', 'MAHLE: OX416D1', 'TECFIL: PEL725', 'FRAM: CH10358ECO'],
          observacao: 'Substituição recomendada a cada 10.000 km.',
          conversaoRef: filtroOleo,
        ),
        HotspotItem(
          id: 'filtro_ar_motor',
          titulo: 'Filtro de Ar do Motor (Admissão)',
          categoria: 'Motor',
          topPercent: 0.15,
          leftPercent: 0.30,
          codigoOem: '17801-0T060',
          equivalentes: const ['MANN: C24016', 'MAHLE: LX4143', 'TECFIL: ARL2203', 'FRAM: CA12056'],
          observacao: 'Garante fluxo laminar de ar para o sistema de injeção direta/indireta D-4S.',
        ),
        HotspotItem(
          id: 'velas_ignicao',
          titulo: 'Jogo de Velas de Ignição Iridium',
          categoria: 'Ignição',
          topPercent: 0.26,
          leftPercent: 0.50,
          codigoOem: '90919-01275',
          equivalentes: const ['NGK: ILKAR7B11', 'DENSO: SC20HR11', 'BOSCH: 0242135518'],
          observacao: 'Eletrodo fino de Iridium de alta condutividade e vida útil de 100.000 km.',
        ),
        HotspotItem(
          id: 'bomba_dagua',
          titulo: 'Bomba d\'Água do Sistema de Arrefecimento',
          categoria: 'Arrefecimento',
          topPercent: 0.32,
          leftPercent: 0.58,
          codigoOem: '16100-39466',
          equivalentes: const ['SCHADEK: 20268', 'URBA: UB0780', 'INDISA: 454010'],
          observacao: 'Rotor metálico balanceado com vedação mecânica em carbeto de silício.',
        ),
        HotspotItem(
          id: 'filtro_cabine',
          titulo: 'Filtro de Cabine / Ar Condicionado (Carvão Ativado)',
          categoria: 'Climatização',
          topPercent: 0.40,
          leftPercent: 0.65,
          codigoOem: '87139-58010',
          equivalentes: const ['MANN: CUK21005', 'MAHLE: LAK923', 'TECFIL: ACP887'],
          observacao: 'Retém 99% de ácaros, poeira e odores externos.',
        ),
      ];
    } else {
      // Transmissão & Direção
      return [
        HotspotItem(
          id: 'junta_homocinetica_esq',
          titulo: 'Junta Homocinética Lado Roda (Esq)',
          categoria: 'Transmissão',
          topPercent: 0.24,
          leftPercent: 0.18,
          codigoOem: '43410-02A40',
          equivalentes: const ['NAKATA: NJH24-410', 'COFAP: JHC08120', 'SPICER: 2240-120'],
          observacao: 'Entalhes: 26 dentes externos / 24 dentes internos.',
        ),
        HotspotItem(
          id: 'junta_homocinetica_dir',
          titulo: 'Junta Homocinética Lado Roda (Dir)',
          categoria: 'Transmissão',
          topPercent: 0.24,
          leftPercent: 0.76,
          codigoOem: '43420-02A40',
          equivalentes: const ['NAKATA: NJH24-411', 'COFAP: JHC08121', 'SPICER: 2240-121'],
          observacao: 'Acompanha coifa de borracha nitrílica, graxa grafitada e abraçadeiras.',
        ),
        HotspotItem(
          id: 'caixa_direcao',
          titulo: 'Caixa de Direção Elétrica (EPS)',
          categoria: 'Direção',
          topPercent: 0.34,
          leftPercent: 0.50,
          codigoOem: '45510-02230',
          equivalentes: const ['TRW: JRM620', 'VIEMAR: 680210', 'NAKATA: NCD9040'],
          observacao: 'Mecanismo de cremalheira com assistência elétrica integrada.',
        ),
        HotspotItem(
          id: 'terminal_direcao_esq',
          titulo: 'Terminal de Direção Esquerdo',
          categoria: 'Direção',
          topPercent: 0.32,
          leftPercent: 0.22,
          codigoOem: '45046-09630',
          equivalentes: const ['VIEMAR: 335290', 'NAKATA: N99180', 'TRW: TS4890'],
          observacao: 'Rosca métrica padrão com porca castelo e cupilha de travamento.',
        ),
        HotspotItem(
          id: 'terminal_direcao_dir',
          titulo: 'Terminal de Direção Direito',
          categoria: 'Direção',
          topPercent: 0.32,
          leftPercent: 0.72,
          codigoOem: '45047-09350',
          equivalentes: const ['VIEMAR: 335291', 'NAKATA: N99181', 'TRW: TS4891'],
          observacao: 'Rosca métrica padrão com porca castelo e cupilha de travamento.',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotspots = _gerarHotspotsParaSistema();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.layers, color: AppTheme.silvaGold),
            SizedBox(width: 8),
            Text('Diagrama Interativo do Veículo'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra de Seleção de Veículo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.silvaGold.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: AppTheme.silvaGold, size: 24),
                  const SizedBox(width: 12),
                  const Text('Veículo:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VeiculoModel>(
                        value: widget.db.veiculos.any((v) => v.id == _veiculoSelecionado.id)
                            ? widget.db.veiculos.firstWhere((v) => v.id == _veiculoSelecionado.id)
                            : widget.db.veiculos.first,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceDark,
                        items: widget.db.veiculos.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text(
                              '${v.montadora} ${v.modelo} ${v.versao} (${v.periodoAno})',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _veiculoSelecionado = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Abas Seletoras de Sistemas do Veículo
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sistemas.map((sistema) {
                  final isSelected = _sistemaAtivo == sistema;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        sistema,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.silvaGold,
                      backgroundColor: AppTheme.surfaceLight,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sistemaAtivo = sistema;
                            _hotspotSelecionado = null;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Dica visual de interação
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.silvaCyan),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passe o mouse sobre os pinos azuis/dourados no diagrama para ver o código OEM e marcas paralelas em tempo real.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Diagrama Esquemático Interativo com Hotspots
            DiagramaHotspotWidget(
              sistemaNome: _sistemaAtivo,
              hotspots: hotspots,
              onSelectHotspot: (item) {
                setState(() => _hotspotSelecionado = item);
              },
              onAbrirFicha: (conv) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversaoDetailScreen(conversao: conv),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 5. Lista Detalhada de Peças do Sistema Selecionado
            Text(
              'Peças Homologadas no Sistema ($_sistemaAtivo):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.silvaGold),
            ),
            const SizedBox(height: 8),

            ...hotspots.map((h) {
              final isSel = _hotspotSelecionado?.id == h.id;

              return Card(
                color: isSel ? AppTheme.surfaceLight : AppTheme.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSel ? AppTheme.silvaGold : AppTheme.dividerColor,
                    width: isSel ? 1.5 : 1.0,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isSel ? AppTheme.silvaGold : AppTheme.surfaceLight,
                    child: Icon(Icons.build, size: 18, color: isSel ? Colors.black : AppTheme.silvaCyan),
                  ),
                  title: Text(
                    h.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text('OEM: ${h.codigoOem}', style: const TextStyle(fontSize: 11, color: AppTheme.silvaCyan, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Marcas: ${h.equivalentes.join(' | ')}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  trailing: h.conversaoRef != null
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConversaoDetailScreen(conversao: h.conversaoRef!),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.silvaGold,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('FICHA', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      : const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
