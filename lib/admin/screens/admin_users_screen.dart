import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../screens/profile/user_profile_screen.dart';
import '../widgets/admin_sidebar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> _users = [];
  List<User> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      _users = await AdminService.getUsers(token);
      _filtered = List.from(_users);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) =>
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await _confirmDialog(
      'Eliminar usuario',
      '¿Eliminar a "${user.name}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;

    try {
      final token = context.read<AuthProvider>().token!;
      await AdminService.deleteUser(token, user.idUser);
      _showSnack('Usuario eliminado', Colors.green);
      _load();
    } catch (e) {
      _showSnack(e.toString(), Colors.red);
    }
  }

  Future<void> _changeRole(User user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final confirmed = await _confirmDialog(
      'Cambiar rol',
      '¿Cambiar el rol de "${user.name}" a $newRole?',
    );
    if (!confirmed) return;

    try {
      final token = context.read<AuthProvider>().token!;
      await AdminService.changeRole(token, user.idUser, newRole);
      _showSnack('Rol actualizado a $newRole', Colors.green);
      _load();
    } catch (e) {
      _showSnack(e.toString(), Colors.red);
    }
  }

  Future<bool> _confirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryColor)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: Row(
        children: [
          const AdminSidebar(selectedIndex: 1),
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
          ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
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
                  const Text('Usuarios',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                  Text('${_users.length} usuarios registrados',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Buscador
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(AppConstants.surfaceColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tabla
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(AppConstants.surfaceColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header tabla
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 1, child: Text('#', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                        Expanded(flex: 3, child: Text('Nombre', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                        Expanded(flex: 3, child: Text('Email', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                        Expanded(flex: 2, child: Text('Registro', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                        Expanded(flex: 1, child: Text('Rol', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                        SizedBox(width: 130, child: Text('Acciones', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),

                  // Filas
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('No se encontraron usuarios', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                            itemBuilder: (_, i) => _UserRow(
                              user: _filtered[i],
                              onDelete: () => _deleteUser(_filtered[i]),
                              onChangeRole: () => _changeRole(_filtered[i]),
                              onViewProfile: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    idUser: _filtered[i].idUser,
                                    initialName: _filtered[i].name,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final User user;
  final VoidCallback onDelete;
  final VoidCallback onChangeRole;
  final VoidCallback onViewProfile;

  const _UserRow({
    required this.user,
    required this.onDelete,
    required this.onChangeRole,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ID
          Expanded(
            flex: 1,
            child: Text('#${user.idUser}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          // Nombre
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isAdmin
                      ? const Color(AppConstants.primaryColor).withOpacity(0.2)
                      : Colors.white.withOpacity(0.08),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isAdmin ? const Color(AppConstants.primaryColor) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Email
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Fecha
          Expanded(
            flex: 2,
            child: Text(
              '${user.fechaRegistro}'.substring(0, 10),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          // Rol
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAdmin
                    ? const Color(AppConstants.primaryColor).withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'User',
                style: TextStyle(
                  color: isAdmin ? const Color(AppConstants.primaryColor) : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Acciones
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: 'Ver perfil completo',
                  child: IconButton(
                    icon: const Icon(Icons.person_search_rounded,
                        color: Colors.teal, size: 18),
                    onPressed: onViewProfile,
                  ),
                ),
                Tooltip(
                  message: isAdmin ? 'Quitar admin' : 'Hacer admin',
                  child: IconButton(
                    icon: Icon(
                      isAdmin ? Icons.person_remove_rounded : Icons.admin_panel_settings_rounded,
                      color: Colors.blue.shade300,
                      size: 18,
                    ),
                    onPressed: onChangeRole,
                  ),
                ),
                Tooltip(
                  message: 'Eliminar usuario',
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                    onPressed: isAdmin ? null : onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}