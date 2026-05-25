import 'package:flutter/material.dart';
import '../services/content_service.dart';
import '../models/content.dart';
import 'dart:math';

class TmdbCollageBackground extends StatefulWidget {
  final Widget child;

  const TmdbCollageBackground({super.key, required this.child});

  @override
  State<TmdbCollageBackground> createState() => _TmdbCollageBackgroundState();
}

class _TmdbCollageBackgroundState extends State<TmdbCollageBackground> {
  List<Content> _contents = [];

  @override
  void initState() {
    super.initState();
    _loadPosters();
  }

  Future<void> _loadPosters() async {
    try {
      final contents = await ContentService.getAllContent();
      if (mounted) {
        setState(() => _contents = contents..shuffle(Random()));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final posters = _contents
        .where((c) => c.posterUrl != null)
        .take(12)
        .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Grid de posters de fondo
        if (posters.isNotEmpty)
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: posters.length,
            itemBuilder: (context, index) {
              return Image.network(
                posters[index].posterUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF2A2A2A)),
              );
            },
          ),

        // Gradiente oscuro de arriba hacia abajo
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.95),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // Contenido encima
        widget.child,
      ],
    );
  }
}