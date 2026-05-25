class AppConstants {
  // URL base del backend en Render
  static const String baseUrl = 'https://proyecto-movietrack-backend.onrender.com';

  // Endpoints de autenticación
  static const String registerUrl = '$baseUrl/auth/register';
  static const String loginUrl = '$baseUrl/auth/login';

  // Endpoints de contenido
  static const String contentUrl = '$baseUrl/content';
  static const String searchMovieUrl = '$baseUrl/content/search/movie';
  static const String searchTvUrl = '$baseUrl/content/search/tv';
  static const String filterUrl = '$baseUrl/content/filter';
  static const String genreListUrl = '$baseUrl/content/genre/movie/list';

  // Endpoints de usuario
  static const String meUrl = '$baseUrl/users/me';

  // Endpoints de favoritos
  static const String favoritesUrl = '$baseUrl/favorites';

  // Endpoints de estado
  static const String statusUrl = '$baseUrl/status';

  // Endpoints de reseñas
  static const String reviewsUrl = '$baseUrl/reviews';

  // Endpoints de admin
  static const String adminUrl = '$baseUrl/admin';

  // TMDB imagen base
  static const String tmdbImageUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbBackdropUrl = 'https://image.tmdb.org/t/p/w1280';

  // Endpoints TMDB directos
  static const String moviePopularUrl = '$baseUrl/content/movie/popular';
  static const String movieTopRatedUrl = '$baseUrl/content/movie/top_rated';
  static const String movieNowPlayingUrl = '$baseUrl/content/movie/now_playing';
  static const String tvPopularUrl = '$baseUrl/content/tv/popular';
  static const String tvTopRatedUrl = '$baseUrl/content/tv/top_rated';
  static const String movieByGenreUrl = '$baseUrl/content/movie/genre';
  static const String tvByGenreUrl = '$baseUrl/content/tv/genre';
  static const String platformsUrl = '$baseUrl/content/tmdb/providers';
  static const String discoverUrl = '$baseUrl/content/discover';

  // Colores de la app
  static const int primaryColor = 0xFFE50914;    // rojo Netflix
  static const int backgroundColor = 0xFF141414; // negro profundo
  static const int surfaceColor = 0xFF1F1F1F;    // gris oscuro
  static const int cardColor = 0xFF2A2A2A;       // gris tarjeta
}