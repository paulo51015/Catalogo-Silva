import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../theme/app_theme.dart';

/// Ponto interativo (Hotspot) no diagrama do veículo
class HotspotItem {
  final String id;
  final String titulo;
  final String categoria;
  final double topPercent; // 0.0 a 1.0 (Posição Y relativa)
  final double leftPercent; // 0.0 a 1.0 (Posição X relativa)
  final String codigoOem;
  final List<String> equivalentes;
  final String observacao;
  final ConversaoModel? conversaoRef;

  const HotspotItem({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.topPercent,
    required this.leftPercent,
    required this.codigoOem,
    required this.equivalentes,
    this.observacao = '',
    this.conversaoRef,
  });
}

/// Widget de Diagrama Esquemático com Hotspots Sensíveis a Mouse Hover e Toque
class DiagramaHotspotWidget extends StatefulWidget {
  final String sistemaNome;
  final List<HotspotItem> hotspots;
  final ValueChanged<HotspotItem>? onSelectHotspot;
  final ValueChanged<ConversaoModel>? onAbrirFicha;

  const DiagramaHotspotWidget({
    super.key,
    required this.sistemaNome,
    required this.hotspots,
    this.onSelectHotspot,
    this.onAbrirFicha,
  });

  @override
  State<DiagramaHotspotWidget> createState() => _DiagramaHotspotWidgetState();
}

class _DiagramaHotspotWidgetState extends State<DiagramaHotspotWidget> with SingleTickerProviderStateMixin {
  HotspotItem? _hoveredItem;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = (width * 0.58).clamp(320.0, 520.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Fundo do Diagrama / Chassis Blueprint
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF09121D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.silvaGold.withOpacity(0.4), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _ChassisBlueprintPainter(sistema: widget.sistemaNome),
              ),
            ),

            // 2. Hotspots Interativos posicionados no Diagrama
            ...widget.hotspots.map((item) {
              final posX = item.leftPercent * (width - 40);
              final posY = item.topPercent * (height - 40);
              final isHovered = _hoveredItem?.id == item.id;

              return Positioned(
                left: posX,
                top: posY,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) {
                    setState(() => _hoveredItem = item);
                    widget.onSelectHotspot?.call(item);
                  },
                  onExit: (_) {
                    setState(() {
                      if (_hoveredItem?.id == item.id) _hoveredItem = null;
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _hoveredItem = item);
                      widget.onSelectHotspot?.call(item);
                      if (item.conversaoRef != null) {
                        widget.onAbrirFicha?.call(item.conversaoRef!);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseScale = 1.0 + (_pulseController.value * 0.25);
                        final glowOpacity = 0.4 + (_pulseController.value * 0.4);

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anel de pulso
                            Container(
                              width: 36 * (isHovered ? 1.3 : pulseScale),
                              height: 36 * (isHovered ? 1.3 : pulseScale),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isHovered ? AppTheme.silvaGold : AppTheme.silvaCyan).withOpacity(glowOpacity * 0.3),
                                border: Border.all(
                                  color: isHovered ? AppTheme.silvaGold : AppTheme.silvaCyan,
                                  width: isHovered ? 2.0 : 1.2,
                                ),
                              ),
                            ),
                            // Ponto central com ícone
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isHovered
                                      ? [AppTheme.silvaGold, AppTheme.silvaOrange]
                                      : [AppTheme.silvaCyan, const Color(0xFF007799)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isHovered ? AppTheme.silvaGold : AppTheme.silvaCyan).withOpacity(0.6),
                                    blurRadius: isHovered ? 10 : 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            }),

            // 3. Card Flutuante de Hover (Tooltip Rico)
            if (_hoveredItem != null)
              Positioned(
                left: (_hoveredItem!.leftPercent * width).clamp(16.0, width - 300.0),
                top: _hoveredItem!.topPercent > 0.5
                    ? (_hoveredItem!.topPercent * height - 150).clamp(10.0, height - 160.0)
                    : (_hoveredItem!.topPercent * height + 35).clamp(10.0, height - 160.0),
                child: _buildHoverCard(_hoveredItem!),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHoverCard(HotspotItem item) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.silvaGold, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, color: AppTheme.silvaGold, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.dividerColor, height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Text('OEM: ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item.codigoOem.isNotEmpty ? item.codigoOem : 'Consultar',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.silvaCyan),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Equivalentes Homologados:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.silvaGold),
            ),
            const SizedBox(height: 2),
            ...item.equivalentes.take(3).map((eq) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    '• $eq',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
            if (item.observacao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.observacao,
                style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.conversaoRef != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onAbrirFicha?.call(item.conversaoRef!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.silvaGold,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('VER FICHA TÉCNICA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pintor customizado para renderizar a grade técnica e o chassi estilizado em Blueprint automotivo
class _ChassisBlueprintPainter extends CustomPainter {
  final String sistema;

  _ChassisBlueprintPainter({required this.sistema});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2E42).withOpacity(0.35)
      ..strokeWidth = 1.0;

    // Grid técnico
    const double step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final blueprintPaint = Paint()
      ..color = const Color(0xFF2A5378).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final w = size.width;
    final h = size.height;

    // Contorno do Veículo / Chassi em vista superior
    final path = Path();
    path.moveTo(w * 0.25, h * 0.15); // Frente esquerda
    path.quadraticBezierTo(w * 0.5, h * 0.10, w * 0.75, h * 0.15); // Bico dianteiro
    path.quadraticBezierTo(w * 0.82, h * 0.35, w * 0.82, h * 0.65); // Lateral direita
    path.quadraticBezierTo(w * 0.75, h * 0.90, w * 0.5, h * 0.90); // Traseira
    path.quadraticBezierTo(w * 0.25, h * 0.90, w * 0.18, h * 0.65); // Lateral esquerda
    path.quadraticBezierTo(w * 0.18, h * 0.35, w * 0.25, h * 0.15);
    canvas.drawPath(path, blueprintPaint);

    // Eixo Dianteiro
    canvas.drawLine(Offset(w * 0.14, h * 0.28), Offset(w * 0.86, h * 0.28), centerPaint);
    // Eixo Traseiro
    canvas.drawLine(Offset(w * 0.14, h * 0.76), Offset(w * 0.86, h * 0.76), centerPaint);
    // Eixo Cardan / Túnel Central
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.88), centerPaint);

    // Rodas Dianteiras
    final rodaPaint = Paint()
      ..color = const Color(0xFF3B6B99)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.11, h * 0.20, w * 0.05, h * 0.16), const Radius.circular(4)), rodaPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.84, h * 0.20, w * 0.05, h * 0.16), const Radius.circular(4)), rodaPaint);

    // Rodas Traseiras
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.11, h * 0.68, w * 0.05, h * 0.16), const Radius.circular(4)), rodaPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.84, h * 0.68, w * 0.05, h * 0.16), const Radius.circular(4)), rodaPaint);

    // Caixa do Motor na Frente
    final motorRect = Rect.fromLTWH(w * 0.38, h * 0.18, w * 0.24, h * 0.20);
    canvas.drawRRect(RRect.fromRectAndRadius(motorRect, const Radius.circular(6)), centerPaint);

    // Título do Diagrama no Canto
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ESQUEMÁTICO TÉCNICO: ${sistema.toUpperCase()}',
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(14, 12));
  }

  @override
  bool shouldRepaint(covariant _ChassisBlueprintPainter oldDelegate) => oldDelegate.sistema != sistema;
}
