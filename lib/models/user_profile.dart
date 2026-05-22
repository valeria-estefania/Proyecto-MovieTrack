class FavoriteEntry {
  final int idFavorite;
  final int idContent;
  final String dateAdded;

  FavoriteEntry({
    required this.idFavorite,
    required this.idContent,
    required this.dateAdded,
  });

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) => FavoriteEntry(
        idFavorite: json['id_favorite'],
        idContent: json['id_content'],
        dateAdded: json['date_added'],
      );
}

class ReviewEntry {
  final int idReview;
  final int idContent;
  final int score;
  final String comment;
  final String date;

  ReviewEntry({
    required this.idReview,
    required this.idContent,
    required this.score,
    required this.comment,
    required this.date,
  });

  factory ReviewEntry.fromJson(Map<String, dynamic> json) => ReviewEntry(
        idReview: json['id_review'],
        idContent: json['id_content'],
        score: json['score'],
        comment: json['comment'],
        date: json['date'],
      );
}

class StatusEntry {
  final int idStatus;
  final int idContent;
  final String status;

  StatusEntry({
    required this.idStatus,
    required this.idContent,
    required this.status,
  });

  factory StatusEntry.fromJson(Map<String, dynamic> json) => StatusEntry(
        idStatus: json['id_status'],
        idContent: json['id_content'],
        status: json['status'],
      );
}

class UserProfile {
  final int idUser;
  final String name;
  final String email;
  final String fechaRegistro;
  final List<FavoriteEntry> favorites;
  final List<ReviewEntry> reviews;
  final List<StatusEntry> statuses;

  UserProfile({
    required this.idUser,
    required this.name,
    required this.email,
    required this.fechaRegistro,
    required this.favorites,
    required this.reviews,
    required this.statuses,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        idUser: json['id_user'],
        name: json['name'],
        email: json['email'],
        fechaRegistro: json['fecha_registro'],
        favorites: (json['favorites'] as List)
            .map((f) => FavoriteEntry.fromJson(f))
            .toList(),
        reviews: (json['reviews'] as List)
            .map((r) => ReviewEntry.fromJson(r))
            .toList(),
        statuses: (json['statuses'] as List)
            .map((s) => StatusEntry.fromJson(s))
            .toList(),
      );
}