import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/content.dart';

class ContentService {
  // Buscar películas
  static Future<List<Content>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('${AppConstants.searchMovieUrl}?query=$query'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Content.fromJson(item)).toList();
    } else {
      throw Exception('No se encontraron películas');
    }
  }

  // Buscar series
  static Future<List<Content>> searchTv(String query) async {
    final response = await http.get(
      Uri.parse('${AppConstants.searchTvUrl}?query=$query'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Content.fromJson(item)).toList();
    } else {
      throw Exception('No se encontraron series');
    }
  }

  // Detalle de película desde TMDB
  static Future<Map<String, dynamic>> getMovieDetail(int tmdbId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.contentUrl}/movie/$tmdbId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Película no encontrada');
    }
  }

  // Detalle de serie desde TMDB
  static Future<Map<String, dynamic>> getTvDetail(int tmdbId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.contentUrl}/tv/$tmdbId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Serie no encontrada');
    }
  }

  // Actores
  static Future<List<dynamic>> getCredits(int tmdbId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.contentUrl}/movie/$tmdbId/credits'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // Recomendaciones
  static Future<List<dynamic>> getRecommendations(int tmdbId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.contentUrl}/movie/$tmdbId/recommendations'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // Filtrar contenido
  static Future<List<Content>> filterContent({
    String? type,
    String? genre,
    String? platform,
  }) async {
    String url = AppConstants.filterUrl;
    List<String> params = [];

    if (type != null) params.add('type=$type');
    if (genre != null) params.add('genre=$genre');
    if (platform != null) params.add('platform=$platform');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Content.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // Obtener todo el contenido guardado en la BD
  static Future<List<Content>> getAllContent() async {
    final response = await http.get(
      Uri.parse(AppConstants.contentUrl),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Content.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // Nuevos metodos para el home_screen 
  static Future<List<dynamic>> getPopularMovies() async {
    final response = await http.get(Uri.parse(AppConstants.moviePopularUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getTopRatedMovies() async {
    final response = await http.get(Uri.parse(AppConstants.movieTopRatedUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getNowPlayingMovies() async {
    final response = await http.get(Uri.parse(AppConstants.movieNowPlayingUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getPopularTv() async {
    final response = await http.get(Uri.parse(AppConstants.tvPopularUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getTopRatedTv() async {
    final response = await http.get(Uri.parse(AppConstants.tvTopRatedUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getMoviesByGenre(int genreId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.movieByGenreUrl}/$genreId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getTvByGenre(int genreId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tvByGenreUrl}/$genreId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getGenres() async {
    final response = await http.get(Uri.parse(AppConstants.genreListUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getPlatforms() async {
    final response = await http.get(
      Uri.parse(AppConstants.platformsUrl),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> discoverByPlatform(int providerId, String type) async {
    final response = await http.get(
      Uri.parse('${AppConstants.discoverUrl}/$type/platform/$providerId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }


  static Future<Content> getOrCreateContent(
      Map<String, dynamic> tmdbItem, String type) async {
    final tmdbId = tmdbItem['id'];
    
    // Busca en nuestra BD
    final allContent = await getAllContent();
    try {
      return allContent.firstWhere((c) => c.tmdbId == tmdbId);
    } catch (_) {
      // No existe, lo guarda buscándolo por nombre
      final query = tmdbItem['title'] ?? tmdbItem['name'] ?? '';
      if (type == 'movie') {
        final results = await searchMovies(query);
        return results.firstWhere((c) => c.tmdbId == tmdbId);
      } else {
        final results = await searchTv(query);
        return results.firstWhere((c) => c.tmdbId == tmdbId);
      }
    }
  }

}

