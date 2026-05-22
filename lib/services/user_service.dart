import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

class UserService {
  static const String _usersUrl = '${AppConstants.baseUrl}/users';

  // ── Buscar usuario por email ────────────────────────────────────────────────
  static Future<User> searchByEmail(String email) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$_usersUrl/search').replace(
      queryParameters: {'email': email},
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    } else {
      throw Exception('Error al buscar usuario');
    }
  }

  // ── Obtener perfil completo ─────────────────────────────────────────────────
  static Future<UserProfile> getFullProfile(int idUser) async {
    final token = await AuthService.getToken();

    final res = await http.get(
      Uri.parse('$_usersUrl/$idUser/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    } else {
      throw Exception('Error al obtener perfil');
    }
  }
}