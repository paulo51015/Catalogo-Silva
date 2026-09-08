import 'package:flutter/material.dart';
import '../../models/conversao_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/conversao_card_widget.dart';
import 'conversao_detail_screen.dart';

class FavoritosScreen extends StatefulWidget {
  final DatabaseService db;

  const FavoritosScreen({super.key, required this.db});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  @override
  Widget build(BuildContext context) {
    final favoritos = widget.db.conversoes.where((c) => c.isFavorito).toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.star, color: AppTheme.silvaGold),
            SizedBox(width: 8),
            Text('Mais Utilizadas (Favoritos)'),
          ],
        ),
      ),
      body: favoritos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_border, size: 64, color: AppTheme.silvaGold),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma conversão favoritada ainda.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toque na estrela de qualquer cartão de peça na busca para salvá-la aqui como uma das mais utilizadas no balcão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritos.length,
              itemBuilder: (context, index) {
                final conv = favoritos[index];
                return ConversaoCardWidget(
                  conversao: conv,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversaoDetailScreen(conversao: conv),
                      ),
                    );
                  },
                  onToggleFavorito: () {
                    widget.db.toggleFavorito(conv.id);
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
