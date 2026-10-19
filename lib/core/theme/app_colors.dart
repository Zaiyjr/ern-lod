import 'package:flutter/material.dart';

/// Dark-map theme mirroring the design tokens in the web mockup:
/// base `#0F172A`, accent `#2563EB`, 44-52pt touch targets.
abstract final class AppColors {
  static const base = Color(0xFF0F172A);
  static const surface = Color(0xFF1E283D);
  static const sheet = Color(0xFF192134);
  static const textPrimary = Color(0xFFF1F5FB);
  static const textSecondary = Color(0xFFA9B7CC);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFF60A5FA);
  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFFCA5A5);
  static const line = Color(0x14FFFFFF); // white @ 8%
  static const lineStrong = Color(0x24FFFFFF); // white @ 14%
}
