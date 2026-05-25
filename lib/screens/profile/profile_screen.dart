import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Por ahora solo cierra el modo edición
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado'),
        backgroundColor: Color(0xFF1F1F1F),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás segura de que quieres cerrar sesión?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              final userProvider = context.read<UserProvider>();
              await authProvider.logout();
              userProvider.clear();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final userProvider = context.watch<UserProvider>();

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF141414),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined,
                color: Colors.white),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFE50914),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            Text(
              user.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(user.email,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),

            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.role == 'admin'
                    ? const Color(0xFFE50914).withOpacity(0.2)
                    : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user.role == 'admin'
                      ? const Color(0xFFE50914)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                user.role == 'admin' ? 'Administrador' : 'Usuario',
                style: TextStyle(
                  color: user.role == 'admin'
                      ? const Color(0xFFE50914)
                      : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Estadísticas
            Row(
              children: [
                _StatCard(
                  label: 'Favoritos',
                  value: userProvider.favorites.length.toString(),
                  icon: Icons.favorite,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Vistos',
                  value: userProvider.statuses
                      .where((s) => s.status == 'visto')
                      .length
                      .toString(),
                  icon: Icons.check_circle,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Reseñas',
                  value: userProvider.myReviews.length.toString(),
                  icon: Icons.rate_review,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Formulario edición
            if (_isEditing) ...[
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nombre',
                  prefixIcon:
                      Icon(Icons.person_outline, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Guardar cambios'),
              ),
              const SizedBox(height: 32),
            ],

            // Opciones
            _OptionTile(
              icon: Icons.info_outline,
              label: 'Miembro desde',
              trailing: user.fechaRegistro,
            ),

            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE50914)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, color: Color(0xFFE50914)),
                label: const Text('Cerrar sesión',
                    style: TextStyle(
                        color: Color(0xFFE50914),
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE50914), size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 15)),
          const Spacer(),
          Text(trailing,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}