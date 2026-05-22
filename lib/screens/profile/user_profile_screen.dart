import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  final int idUser;
  final String? initialName; // opcional, para mostrar antes de cargar

  const UserProfileScreen({
    super.key,
    required this.idUser,
    this.initialName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.getFullProfile(widget.idUser);
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.initialName ?? 'Perfil de usuario',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadProfile)
              : _ProfileBody(profile: _profile!, tabController: _tabController),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final TabController tabController;

  const _ProfileBody({required this.profile, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final vistos = profile.statuses.where((s) => s.status == 'visto').length;
    final pendientes = profile.statuses.where((s) => s.status == 'pendiente').length;
    final avgScore = profile.reviews.isEmpty
        ? null
        : profile.reviews.map((r) => r.score).reduce((a, b) => a + b) /
            profile.reviews.length;

    return Column(
      children: [
        // ── Cabecera ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          color: const Color(0xFF1A1A1A),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFE50914),
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(profile.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(profile.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Miembro desde ${profile.fechaRegistro}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),

              const SizedBox(height: 20),

              // Stats rápidas
              Row(children: [
                _QuickStat(label: 'Favoritos', value: '${profile.favorites.length}', icon: Icons.favorite),
                _QuickStat(label: 'Vistos', value: '$vistos', icon: Icons.check_circle),
                _QuickStat(label: 'Pendientes', value: '$pendientes', icon: Icons.watch_later),
                _QuickStat(
                  label: 'Nota media',
                  value: avgScore != null ? avgScore.toStringAsFixed(1) : '—',
                  icon: Icons.star,
                ),
              ]),
            ],
          ),
        ),

        // ── Tabs ──────────────────────────────────────────────────
        TabBar(
          controller: tabController,
          indicatorColor: const Color(0xFFE50914),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Favoritos'),
            Tab(text: 'Reseñas'),
            Tab(text: 'Estados'),
          ],
        ),

        // ── Contenido de tabs ─────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _FavoritesTab(favorites: profile.favorites),
              _ReviewsTab(reviews: profile.reviews),
              _StatusesTab(statuses: profile.statuses),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _FavoritesTab extends StatelessWidget {
  final List<FavoriteEntry> favorites;
  const _FavoritesTab({required this.favorites});

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const _EmptyState(icon: Icons.favorite_border, text: 'Sin favoritos aún');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (_, i) {
        final f = favorites[i];
        return _ListTileCard(
          icon: Icons.favorite,
          iconColor: const Color(0xFFE50914),
          title: 'Contenido #${f.idContent}',
          subtitle: 'Añadido el ${f.dateAdded}',
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final List<ReviewEntry> reviews;
  const _ReviewsTab({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const _EmptyState(icon: Icons.rate_review_outlined, text: 'Sin reseñas aún');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (_, i) {
        final r = reviews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.movie_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text('Contenido #${r.idContent}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              // Score stars
              Row(children: List.generate(5, (j) => Icon(
                j < r.score ? Icons.star : Icons.star_border,
                color: const Color(0xFFE50914),
                size: 14,
              ))),
              const SizedBox(width: 4),
              Text('${r.score}/5',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(r.comment, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 6),
            Text(r.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        );
      },
    );
  }
}

class _StatusesTab extends StatelessWidget {
  final List<StatusEntry> statuses;
  const _StatusesTab({required this.statuses});

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const _EmptyState(icon: Icons.playlist_add_outlined, text: 'Sin estados aún');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statuses.length,
      itemBuilder: (_, i) {
        final s = statuses[i];
        final isVisto = s.status == 'visto';
        return _ListTileCard(
          icon: isVisto ? Icons.check_circle : Icons.watch_later,
          iconColor: isVisto ? Colors.green : Colors.orange,
          title: 'Contenido #${s.idContent}',
          subtitle: isVisto ? 'Visto' : 'Pendiente',
        );
      },
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: const Color(0xFFE50914), size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ListTileCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.grey, size: 48),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    );
  }
}