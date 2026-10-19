import 'package:equatable/equatable.dart';

/// Auth-domain user entity.
///
/// Pure Dart — no Flutter or data-layer imports, so the domain layer
/// stays testable in isolation. The data layer maps its `UserModel`
/// to this via `toEntity()`.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, email, displayName, photoUrl];
}
