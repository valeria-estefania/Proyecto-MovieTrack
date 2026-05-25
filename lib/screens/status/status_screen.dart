import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/content_service.dart';
import '../../models/content.dart';
import '../../models/display_status.dart';
import '../../widgets/bottom_nav.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Content> _vistos = [];
  List<Content> _pendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final userProvider = context.read<UserProvider>();
    final statuses = userProvider.statuses;
    final allContent = await ContentService.getAllContent();

    List<Content> vistos = [];
    List<Content> pendientes = [];

    for (final status in statuses) {
      try {
        final content =
            allContent.firstWhere((c) => c.idContent == status.idContent);
        if (status.status == 'visto') {
          vistos.add(content);
        } else {
          pendientes.add(content);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _vistos = vistos;
        _pendientes = pendientes;
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
        title: const Text('Mis estados'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE50914),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Vistos (${_vistos.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Pendientes (${_pendientes.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : TabBarView(
              controller: _tabController,
              children: [
                _ContentList(
                  contents: _vistos,
                  emptyMessage: 'No has marcado nada como visto',
                  emptyIcon: Icons.check_circle_outline,
                  onRefresh: _loadStatus, // ← nuevo
                ),
                _ContentList(
                  contents: _pendientes,
                  emptyMessage: 'No tienes contenido pendiente',
                  emptyIcon: Icons.bookmark_outline,
                  onRefresh: _loadStatus, // ← nuevo
                ),
              ],
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

class _ContentList extends StatelessWidget {
  final List<Content> contents;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onRefresh; // ← nuevo

  const _ContentList({
    required this.contents,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh, // ← nuevo
  });

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final content = contents[index];
        return GestureDetector(
          onTap: ()  async {
  await Navigator.pushNamed(
    context,
    '/detail',
    arguments: {
      'contentId': content.idContent,
      'tmdbId': content.tmdbId,
      'type': content.type,
    },
    
  );
  onRefresh();
},

          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Poster
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12)),
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
                          child: const Icon(Icons.movie, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFD700), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            content.rating != null
                                ? content.rating!.toStringAsFixed(1)
                                : 'N/A',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              content.type == 'movie' ? 'Película' : 'Serie',
                              style: const TextStyle(
                                  color: Color(0xFFE50914), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}