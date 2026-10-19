import 'package:flutter/material.dart';

import 'app.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dependency graph (datasources → repository → use cases → bloc)
  // must exist before the first frame builds the app.
  await initInjection();

  runApp(const RideBookingApp());
}
