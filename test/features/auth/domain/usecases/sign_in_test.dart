import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/core/error/failures.dart';
import 'package:ride_booking/features/auth/domain/entities/user.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_in.dart';

import '../../helpers/fakes.dart';

void main() {
  const params = SignInParams(email: 'rider@example.com', password: 'hunter2');
  const user = User(id: '42', email: 'rider@example.com');

  test('on success returns the user and caches the session', () async {
    final repository = FakeAuthRepository(user: user);
    final signIn = SignIn(repository);

    final result = await signIn(params);

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw StateError('expected Right')), user);
    expect(repository.cacheSessionCalled, isTrue);
  });

  test('on failure returns the Left and does not cache', () async {
    final repository = FakeAuthRepository(
      user: user,
      signInFailure: const InvalidCredentialsFailure(),
    );
    final signIn = SignIn(repository);

    final result = await signIn(params);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
      (_) => fail('expected a Left'),
    );
    expect(repository.cacheSessionCalled, isFalse);
  });
}
