import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/content_service.dart';
import '../../models/content.dart';
import '../../models/review.dart';
import '../../widgets/bottom_nav.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  Map<int, Content> _contentMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.loadUserData();
    
    final reviews = userProvider.myReviews;
    print('Total reseñas: ${reviews.length}');
    
    final allContent = await ContentService.getAllContent();
    print('Total contenido en BD: ${allContent.length}');
    
    for (final review in reviews) {
      print('Buscando id_content: ${review.idContent}');
      try {
        final content = allContent.firstWhere((c) => c.idContent == review.idContent);
        print('Encontrado: ${content.title}');
      } catch (e) {
        print('NO encontrado: ${review.idContent}');
      }
    }

    Map<int, Content> contentMap = {};
    for (final review in reviews) {
      try {
        final content = allContent.firstWhere((c) => c.idContent == review.idContent);
        contentMap[review.idContent] = content;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _contentMap = contentMap;
        _isLoading = false;
      });
    }
}

  Future<void> _deleteReview(int idReview) async {
    final userProvider = context.read<UserProvider>();
    await userProvider.deleteReview(idReview);
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final reviews = userProvider.myReviews;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis reseñas'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : reviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          color: Colors.grey, size: 64),
                      SizedBox(height: 16),
                      Text('No has escrito reseñas todavía',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final content = _contentMap[review.idContent];

                    return GestureDetector(
                      onTap: () {
                        if (content != null) {
                          Navigator.pushNamed(
                            context,
                            '/detail',
                            arguments: {
                              'contentId': content.idContent,
                              'tmdbId': content.tmdbId,
                              'type': content.type,
                            },
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Contenido info
                            if (content != null)
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                    ),
                                    child: content.posterUrl != null
                                        ? Image.network(
                                            content.posterUrl!,
                                            width: 70,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 70,
                                            height: 100,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(Icons.movie,
                                                color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          content.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE50914)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            content.type == 'movie'
                                                ? 'Película'
                                                : 'Serie',
                                            style: const TextStyle(
                                                color: Color(0xFFE50914),
                                                fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor:
                                            const Color(0xFF1F1F1F),
                                        title: const Text('Eliminar reseña',
                                            style: TextStyle(
                                                color: Colors.white)),
                                        content: const Text(
                                            '¿Estás segura de que quieres eliminar esta reseña?',
                                            style: TextStyle(
                                                color: Colors.grey)),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancelar',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await _deleteReview(
                                                  review.idReview);
                                            },
                                            child: const Text('Eliminar',
                                                style: TextStyle(
                                                    color: Color(0xFFE50914))),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            // Reseña info
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Color(0xFFFFD700), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${review.score}/10',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        review.date,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (review.comment != null &&
                                      review.comment!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      review.comment!,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}