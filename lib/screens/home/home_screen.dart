import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/content_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../providers/content_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Datos TMDB
  List<dynamic> _popularMovies = [];
  List<dynamic> _topRatedMovies = [];
  List<dynamic> _nowPlaying = [];
  List<dynamic> _popularTv = [];
  List<dynamic> _topRatedTv = [];
  List<dynamic> _genres = [];

  // Filtros
  String _contentType = 'movie';
  int? _selectedGenreId;
  String? _selectedGenreName;
  List<dynamic> _filteredByGenre = [];

  bool _isLoading = true;

  List<dynamic> _platforms = [];
  int? _selectedPlatformId;
  String? _selectedPlatformName;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ContentService.getPopularMovies(),
        ContentService.getTopRatedMovies(),
        ContentService.getNowPlayingMovies(),
        ContentService.getPopularTv(),
        ContentService.getTopRatedTv(),
        ContentService.getGenres(),
        ContentService.getPlatforms(),
      ]);
      print('PLATAFORMAS length: ${results[6].length}');
      print('PLATAFORMAS primero: ${results[6].isNotEmpty ? results[6][0] : "VACIO"}');
      print('GENEROS length: ${results[5].length}');
      

      if (mounted) {
        setState(() {
          _popularMovies = results[0];
          _topRatedMovies = results[1];
          _nowPlaying = results[2];
          _popularTv = results[3];
          _topRatedTv = results[4];
          _genres = results[5];
          _platforms = results[6];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByGenre(int genreId, String genreName) async {
    setState(() {
      _selectedGenreId = genreId;
      _selectedGenreName = genreName;
    });

    final results = _contentType == 'movie'
        ? await ContentService.getMoviesByGenre(genreId)
        : await ContentService.getTvByGenre(genreId);

    if (mounted) setState(() => _filteredByGenre = results);
  }

  void _clearGenre() {
    setState(() {
      _selectedGenreId = null;
      _selectedGenreName = null;
      _filteredByGenre = [];
      _selectedPlatformId = null;
      _selectedPlatformName = null;
      _filteredByGenre = [];
    });
  }

  Future<void> _filterByPlatform(int platformId, String platformName) async {
    setState(() {
      _selectedPlatformId = platformId;
      _selectedPlatformName = platformName;
      _selectedGenreId = null;
      _selectedGenreName = null;
      _filteredByGenre = [];
    });

    final results = await ContentService.discoverByPlatform(
      platformId,
      _contentType,
    );

    if (mounted) setState(() => _filteredByGenre = results);
  }

 void _navigateToDetail(Map<String, dynamic> item, String type) async {
  try {
    final content = await ContentService.getOrCreateContent(item, type);
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/detail',
      arguments: {
        'contentId': content.idContent,
        'tmdbId': content.tmdbId,
        'type': content.type,
      },
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al cargar el contenido'),
        backgroundColor: Color(0xFFE50914),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MOVIETRACK',
            style: TextStyle(
                color: Color(0xFFE50914),
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE50914),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ContentProvider>().clearResults();
          Navigator.pushNamed(context, '/search');
        },
        backgroundColor: const Color(0xFFE50914),
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: const Color(0xFFE50914),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle película/serie
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _TypeButton(
                                label: 'Películas',
                                isSelected: _contentType == 'movie',
                                onTap: () {
                                  setState(() {
                                    _contentType = 'movie';
                                    _selectedGenreId = null;
                                    _selectedGenreName = null;
                                    _filteredByGenre = [];
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _TypeButton(
                                label: 'Series',
                                isSelected: _contentType == 'tv',
                                onTap: () {
                                  setState(() {
                                    _contentType = 'tv';
                                    _selectedGenreId = null;
                                    _selectedGenreName = null;
                                    _filteredByGenre = [];
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Géneros horizontales
                        if (_genres.isNotEmpty) ...[
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _genres.length,
                              itemBuilder: (context, index) {
                                final genre = _genres[index];
                                final isSelected =
                                    _selectedGenreId == genre['id'];
                                return GestureDetector(
                                  onTap: () => isSelected
                                      ? _clearGenre()
                                      : _filterByGenre(
                                          genre['id'], genre['name']),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE50914)
                                          : const Color(0xFF1F1F1F),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFE50914)
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      genre['name'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Plataformas horizontales
                        if (_platforms.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _platforms.length,
                              itemBuilder: (context, index) {
                                final platform = _platforms[index];
                                final isSelected =
                                    _selectedPlatformId == platform['provider_id'];
                                final logoPath = platform['logo_path'];

                                return GestureDetector(
                                  onTap: () => isSelected
                                      ? _clearGenre()
                                      : _filterByPlatform(
                                          platform['provider_id'],
                                          platform['provider_name'],
                                        ),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
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
                                      children: [
                                        if (logoPath != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              'https://image.tmdb.org/t/p/w200$logoPath',
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox(),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          platform['provider_name'],
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Si hay filtro por género
                        if (_selectedGenreId != null || _selectedPlatformId != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  _selectedGenreName ?? _selectedPlatformName ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _clearGenre,
                                  child: const Text('Ver todo',
                                      style: TextStyle(color: Color(0xFFE50914))),
                                ),
                              ],
                            ),
                          ),
                          _HorizontalList(
                            items: _filteredByGenre,
                            type: _contentType,
                            onTap: (item) => _navigateToDetail(item, _contentType),
                          ),
                        ] else ...[
                          // Secciones normales
                          if (_contentType == 'movie') ...[
                            _SectionTitle(title: 'Populares'),
                            _HorizontalList(
                              items: _popularMovies,
                              type: 'movie',
                              onTap: (item) =>
                                  _navigateToDetail(item, 'movie'),
                            ),
                            _SectionTitle(title: 'Mejor valoradas'),
                            _HorizontalList(
                              items: _topRatedMovies,
                              type: 'movie',
                              onTap: (item) =>
                                  _navigateToDetail(item, 'movie'),
                            ),
                            _SectionTitle(title: 'En cines'),
                            _HorizontalList(
                              items: _nowPlaying,
                              type: 'movie',
                              onTap: (item) =>
                                  _navigateToDetail(item, 'movie'),
                            ),
                          ] else ...[
                            _SectionTitle(title: 'Series populares'),
                            _HorizontalList(
                              items: _popularTv,
                              type: 'tv',
                              onTap: (item) =>
                                  _navigateToDetail(item, 'tv'),
                            ),
                            _SectionTitle(title: 'Mejor valoradas'),
                            _HorizontalList(
                              items: _topRatedTv,
                              type: 'tv',
                              onTap: (item) =>
                                  _navigateToDetail(item, 'tv'),
                            ),
                          ],
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE50914)
              : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HorizontalList extends StatelessWidget {
  final List<dynamic> items;
  final String type;
  final Function(Map<String, dynamic>) onTap;

  const _HorizontalList({
    required this.items,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(height: 160);
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final posterPath = item['poster_path'];
          final title = item['title'] ?? item['name'] ?? '';
          final rating = (item['vote_average'] ?? 0.0).toDouble();

          return GestureDetector(
            onTap: () => onTap(item),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w500$posterPath',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(Icons.movie,
                                    color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(Icons.movie,
                                  color: Colors.grey),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFD700), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}