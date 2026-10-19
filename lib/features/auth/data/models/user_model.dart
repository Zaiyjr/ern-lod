import '../../domain/entities/user.dart';

/// Wire representation of [User], with JSON (de)serialisation and
/// conversion to the domain entity.
///
/// Hand-written rather than freezed-generated so the auth slice stays
/// free of a build_runner step; the `toEntity()` boundary is what the
/// rest of the app consumes.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
      };

  /// Maps the wire model to the domain entity, dropping data-layer types.
  User toEntity() => User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
