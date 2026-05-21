import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../providers/user_provider.dart';
import '../../services/content_service.dart';
import '../../services/review_service.dart';
import '../../models/review.dart';

class DetailScreen extends StatefulWidget {
  final int contentId;
  final int tmdbId;
  final String type;

  const DetailScreen({
    super.key,
    required this.contentId,
    required this.tmdbId,
    required this.type,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? _detail;
  List<dynamic> _cast = [];
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = widget.type == 'movie'
          ? await ContentService.getMovieDetail(widget.tmdbId)
          : await ContentService.getTvDetail(widget.tmdbId);

      final cast = widget.type == 'movie'
          ? await ContentService.getCredits(widget.tmdbId)
          : [];

      final reviews =
          await ReviewService.getReviewsByContent(widget.contentId);

      if (mounted) {
        setState(() {
          _detail = detail;
          _cast = cast;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReviewDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final existingReview = userProvider.myReviews
        .where((r) => r.idContent == widget.contentId)
        .firstOrNull;

    int score = existingReview?.score ?? 5;
    final commentController =
        TextEditingController(text: existingReview?.comment ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existingReview != null ? 'Editar reseña' : 'Escribir reseña',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Calificación',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: score.toDouble(),
                minRating: 1,
                maxRating: 10,
                itemCount: 10,
                itemSize: 28,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Color(0xFFFFD700)),
                onRatingUpdate: (rating) {
                  setModalState(() => score = rating.toInt());
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Comentario (opcional)',
                  filled: true,
                  fillColor: Color(0xFF2A2A2A),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (existingReview != null) {
                      await userProvider.updateReview(
                          existingReview.idReview, score, commentController.text);
                    } else {
                      await userProvider.createReview(
                          widget.contentId, score, commentController.text);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    final reviews = await ReviewService.getReviewsByContent(
                        widget.contentId);
                    setState(() => _reviews = reviews);
                  },
                  child: Text(existingReview != null ? 'Actualizar' : 'Publicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isFav = userProvider.isFavorite(widget.contentId);
    final currentStatus = userProvider.getStatus(widget.contentId);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF141414),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914))),
      );
    }

    if (_detail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF141414),
        appBar: AppBar(),
        body: const Center(
            child: Text('No se pudo cargar', style: TextStyle(color: Colors.white))),
      );
    }

    final backdropPath = _detail!['backdrop_path'];
    final backdropUrl = backdropPath != null
        ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
        : null;
    final title = _detail!['title'] ?? _detail!['name'] ?? '';
    final overview = _detail!['overview'] ?? '';
    final releaseDate =
        _detail!['release_date'] ?? _detail!['first_air_date'] ?? '';
    final voteAverage =
        (_detail!['vote_average'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: CustomScrollView(
        slivers: [
          // Backdrop con AppBar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF141414),
            flexibleSpace: FlexibleSpaceBar(
              background: backdropUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(backdropUrl, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: const Color(0xFF1F1F1F)),
            ),
            actions: [
              // Favorito
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_outline,
                  color: isFav ? const Color(0xFFE50914) : Colors.white,
                ),
                onPressed: () =>
                    userProvider.toggleFavorite(widget.contentId),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y rating
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 4),
                      Text(voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(width: 16),
                      if (releaseDate.isNotEmpty)
                        Text(releaseDate.substring(0, 4),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Estado
                  Row(
                    children: [
                      _StatusButton(
                        label: 'Visto',
                        icon: Icons.check_circle_outline,
                        isSelected: currentStatus == 'visto',
                        onTap: () => userProvider.setStatus(
                            widget.contentId, 'visto'),
                      ),
                      const SizedBox(width: 8),
                      _StatusButton(
                        label: 'Pendiente',
                        icon: Icons.bookmark_outline,
                        isSelected: currentStatus == 'pendiente',
                        onTap: () => userProvider.setStatus(
                            widget.contentId, 'pendiente'),
                      ),
                      const SizedBox(width: 8),
                      _StatusButton(
                        label: 'Reseña',
                        icon: Icons.rate_review_outlined,
                        isSelected: false,
                        onTap: () => _showReviewDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sinopsis
                  if (overview.isNotEmpty) ...[
                    const Text('Sinopsis',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(overview,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            height: 1.5)),
                    const SizedBox(height: 24),
                  ],

                  // Reparto
                  if (_cast.isNotEmpty) ...[
                    const Text('Reparto',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.take(10).length,
                        itemBuilder: (context, index) {
                          final actor = _cast[index];
                          final photoPath = actor['profile_path'];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  backgroundImage: photoPath != null
                                      ? NetworkImage(
                                          'https://image.tmdb.org/t/p/w200$photoPath')
                                      : null,
                                  child: photoPath == null
                                      ? const Icon(Icons.person,
                                          color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  actor['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reseñas
                  const Text('Reseñas',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    const Text('Sin reseñas todavía',
                        style: TextStyle(color: Colors.grey))
                  else
                    ..._reviews.map((r) => _ReviewCard(review: r)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE50914)
                : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE50914)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 4),
              Text('${review.score}/10',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(review.date,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}