/// Presentation demo credentials, shown on the login page for easy
/// exploration of the app ("Use demo account" quick sign-in).
///
/// These must be kept in sync with the offline MockHttpClient's seeded
/// user which stands in for the real backend while auth is mocked.
abstract final class DemoAccount {
  static const email = 'alex@example.com';
  static const password = 'password123';
  static const displayName = 'Alex Rider';
}
