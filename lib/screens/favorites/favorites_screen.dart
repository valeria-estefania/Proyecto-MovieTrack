import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/content_service.dart';
import '../../models/content.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/bottom_nav.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Content> _contents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userProvider = context.read<UserProvider>();
    final favorites = userProvider.favorites;

    List<Content> contents = [];
    for (final fav in favorites) {
      try {
        final all = await ContentService.getAllContent();
        final content = all.firstWhere((c) => c.idContent == fav.idContent);
        contents.add(content);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _contents = contents;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis favoritos'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _contents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline,
                          color: Colors.grey, size: 64),
                      SizedBox(height: 16),
                      Text('No tienes favoritos todavía',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _contents.length,
                  itemBuilder: (context, index) {
                    return MovieCard(content: _contents[index]);
                  },
                ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}