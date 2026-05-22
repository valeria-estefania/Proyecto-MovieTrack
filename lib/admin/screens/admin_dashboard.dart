import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/stat_card.dart';
import 'admin_reviews_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentReviews = [];
  List<Map<String, dynamic>> _scoreDistribution = [];
  List<Map<String, dynamic>> _registrosPorMes = [];
  List<Map<String, dynamic>> _favoritosPorTipo = [];
  List<Map<String, dynamic>> _usuariosActivos = [];
  List<Map<String, dynamic>> _topFavoritos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final results = await Future.wait([
        AdminService.getStats(token),
        AdminService.getRecentReviews(token),
        AdminService.getScoreDistribution(token),
        AdminService.getRegistrosPorMes(token),
        AdminService.getFavoritosPorTipo(token),
        AdminService.getUsuariosActivos(token),
        AdminService.getTopFavoritos(token),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _recentReviews = (results[1] as List).cast<Map<String, dynamic>>();
        _scoreDistribution = (results[2] as List).cast<Map<String, dynamic>>();
        _registrosPorMes = (results[3] as List).cast<Map<String, dynamic>>();
        _favoritosPorTipo = (results[4] as List).cast<Map<String, dynamic>>();
        _usuariosActivos = (results[5] as List).cast<Map<String, dynamic>>();
        _topFavoritos = (results[6] as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: Row(
        children: [
          const AdminSidebar(selectedIndex: 0),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(AppConstants.primaryColor)))
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadStats, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resumen general de la plataforma',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                tooltip: 'Actualizar',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Stat cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                title: 'Usuarios',
                value: '${s['total_usuarios'] ?? 0}',
                icon: Icons.people_rounded,
                color: const Color(0xFF4A90D9),
              ),
              StatCard(
                title: 'Películas/Series',
                value: '${s['total_contenido'] ?? 0}',
                icon: Icons.movie_rounded,
                color: const Color(0xFF7B68EE),
              ),
              StatCard(
                title: 'Reviews',
                value: '${s['total_reviews'] ?? 0}',
                icon: Icons.rate_review_rounded,
                color: const Color(AppConstants.primaryColor),
              ),
              StatCard(
                title: 'Favoritos',
                value: '${s['total_favoritos'] ?? 0}',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Fila 1: Estado del contenido + Reviews recientes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildWatchStatus(s),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _buildRecentReviews(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Fila 2: Histograma de scores + Películas vs Series
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildScoreHistogram(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildTipoDonut(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Fila 3: Registros por mes (ancho completo)
          _buildRegistrosPorMes(),

          const SizedBox(height: 20),

          // Fila 4: Top favoritos + Usuarios más activos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopFavoritos()),
              const SizedBox(width: 16),
              Expanded(child: _buildUsuariosActivos()),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Watch Status ────────────────────────────────────────────
  Widget _buildWatchStatus(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado del contenido',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatusIndicator(
                label: 'Visto',
                count: s['contenido_visto'] ?? 0,
                color: Colors.green,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(width: 32),
              _StatusIndicator(
                label: 'Pendiente',
                count: s['contenido_pendiente'] ?? 0,
                color: Colors.orange,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(
            visto: s['contenido_visto'] ?? 0,
            pendiente: s['contenido_pendiente'] ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({required int visto, required int pendiente}) {
    final total = visto + pendiente;
    if (total == 0) return const SizedBox();
    final ratio = visto / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Vistos ${(ratio * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Pendientes ${((1 - ratio) * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.orange.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.green),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  // ─── Reviews recientes ───────────────────────────────────────
  Widget _buildRecentReviews() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews recientes',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AdminReviewsScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                ),
                child: const Text('Ver todas →', style: TextStyle(color: Color(AppConstants.primaryColor))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentReviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Sin reviews aún', style: TextStyle(color: Colors.grey))),
            )
          else
            ...(_recentReviews.map((r) => _RecentReviewItem(review: r))),
        ],
      ),
    );
  }

  // ─── Histograma de scores ────────────────────────────────────
  Widget _buildScoreHistogram() {
    if (_scoreDistribution.isEmpty) return const SizedBox();
    final maxVal = _scoreDistribution
        .map((e) => (e['total'] as int? ?? 0))
        .fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de scores',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('¿Qué tan generosos son tus usuarios?',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _scoreDistribution.map((item) {
                final score = item['score'] as int? ?? 0;
                final total = item['total'] as int? ?? 0;
                final ratio = maxVal > 0 ? total / maxVal : 0.0;

                Color barColor;
                if (score <= 4) barColor = const Color(0xFFE50914);
                else if (score <= 6) barColor = Colors.orange;
                else barColor = Colors.green;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (total > 0)
                          Text('$total',
                              style: const TextStyle(color: Colors.grey, fontSize: 9)),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: 110 * ratio,
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$score',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Películas vs Series (donut) ─────────────────────────────
  Widget _buildTipoDonut() {
    if (_favoritosPorTipo.isEmpty) return const SizedBox();

    int movies = 0, tv = 0;
    for (final item in _favoritosPorTipo) {
      if (item['type'] == 'movie') movies = item['total'] as int? ?? 0;
      if (item['type'] == 'tv') tv = item['total'] as int? ?? 0;
    }
    final total = movies + tv;
    final moviePct = total > 0 ? (movies / total * 100).toStringAsFixed(1) : '0';
    final tvPct = total > 0 ? (tv / total * 100).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Películas vs series',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Por favoritos totales',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _DonutPainter(
                    movieRatio: total > 0 ? movies / total : 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: const Color(0xFFE50914), label: 'Películas', value: '$moviePct%'),
                  const SizedBox(height: 12),
                  _LegendItem(color: const Color(0xFF4A90D9), label: 'Series', value: '$tvPct%'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Registros por mes ───────────────────────────────────────
  Widget _buildRegistrosPorMes() {
    if (_registrosPorMes.isEmpty) return const SizedBox();
    final maxVal = _registrosPorMes
        .map((e) => (e['total'] as int? ?? 0))
        .fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registros por mes',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Crecimiento de la base de usuarios',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _registrosPorMes.map((item) {
                final mes = (item['mes'] as String? ?? '').substring(5);
                final total = item['total'] as int? ?? 0;
                final ratio = maxVal > 0 ? total / maxVal : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$total',
                            style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: 110 * ratio,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90D9).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(mes,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top favoritos ───────────────────────────────────────────
  Widget _buildTopFavoritos() {
    if (_topFavoritos.isEmpty) return const SizedBox();
    final maxVal = (_topFavoritos.first['total_favoritos'] as int? ?? 1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top favoritos',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Los más marcados por usuarios',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          ..._topFavoritos.take(5).map((item) {
            final title = item['title'] as String? ?? '';
            final total = item['total_favoritos'] as int? ?? 0;
            final ratio = maxVal > 0 ? total / maxVal : 0.0;
            return _BarRow(
              label: title,
              value: '$total',
              ratio: ratio,
              color: const Color(0xFFFF6B6B),
            );
          }),
        ],
      ),
    );
  }

  // ─── Usuarios más activos ────────────────────────────────────
  Widget _buildUsuariosActivos() {
    if (_usuariosActivos.isEmpty) return const SizedBox();
    final maxVal = (_usuariosActivos.first['total_reviews'] as int? ?? 1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usuarios más activos',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Por cantidad de reviews escritas',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          ..._usuariosActivos.take(5).map((item) {
            final name = item['name'] as String? ?? '';
            final total = item['total_reviews'] as int? ?? 0;
            final ratio = maxVal > 0 ? total / maxVal : 0.0;
            return _BarRow(
              label: name,
              value: '$total',
              ratio: ratio,
              color: const Color(0xFF7B68EE),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────

class _BarRow extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;
  final Color color;

  const _BarRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double movieRatio;
  const _DonutPainter({required this.movieRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final fullAngle = 2 * 3.14159265;

    paint.color = const Color(0xFFE50914);
    canvas.drawArc(rect, -1.5708, fullAngle * movieRatio, false, paint);

    paint.color = const Color(0xFF4A90D9);
    canvas.drawArc(rect, -1.5708 + fullAngle * movieRatio, fullAngle * (1 - movieRatio), false, paint);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.movieRatio != movieRatio;
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusIndicator({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count',
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _RecentReviewItem extends StatelessWidget {
  final Map<String, dynamic> review;
  const _RecentReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final score = review['score'] as int? ?? 0;
    final scoreColor = score >= 7 ? Colors.green : score >= 5 ? Colors.orange : Colors.red;
    final userName = review['user']?['name'] as String? ?? 'Usuario';
    final contentTitle = review['content']?['title'] as String? ?? 'Contenido desconocido';
    final comment = review['comment'] as String? ?? '';
    final date = review['date'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$score',
                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(contentTitle,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('por $userName',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(comment,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}