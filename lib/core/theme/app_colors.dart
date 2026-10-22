import 'package:flutter/material.dart';

/// Dark-map theme mirroring the design tokens in the web mockup:
/// base `#0F172A`, accent `#2563EB`, 44-52pt touch targets.
abstract final class AppColors {
  // Light & Airy palette (Uber / Airbnb design system)
  static const base = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const sheet = Color(0xFFFFFFFF);
  static const cardSubtle = Color(0xFFF1F5F9);
  
  static const textPrimary = Color(0xFF090E17);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  static const brand = Color(0xFF0F172A); // bold primary slate
  static const accent = Color(0xFF2563EB); // electric blue
  static const accentSoft = Color(0xFF3B82F6);
  static const accentTint = Color(0xFFEFF6FF);

  static const success = Color(0xFF10B981);
  static const successTint = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const dangerTint = Color(0xFFFEF2F2);

  static const tint = Color(0x1A2563EB); // accent @ 10%
  static const line = Color(0x140F172A); // slate @ 8%
  static const lineStrong = Color(0x260F172A); // slate @ 15%
}

