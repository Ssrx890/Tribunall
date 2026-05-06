import 'package:flutter/material.dart';

import '../models/nivel_juego.dart';

class AppThemeData {
  final Color fondo;
  final Color superficie;
  final Color borde;
  final Color accent;
  final Color accent2;
  final Color rojoBright;
  final Color textoPrim;
  final Color textoSec;
  final Color textoApagado;

  const AppThemeData({
    required this.fondo,
    required this.superficie,
    required this.borde,
    required this.accent,
    required this.accent2,
    required this.rojoBright,
    required this.textoPrim,
    required this.textoSec,
    required this.textoApagado,
  });

  static const normal = AppThemeData(
    fondo: Color(0xFF0F0E1A),
    superficie: Color(0xFF1B1930),
    borde: Color(0xFF2D2A4A),
    accent: Color(0xFFFFBD2E),
    accent2: Color(0xFFFF9A00),
    rojoBright: Color(0xFFFF4D6D),
    textoPrim: Color(0xFFF2EEFF),
    textoSec: Color(0xFF9B91C4),
    textoApagado: Color(0xFF4E496E),
  );

  static const intermedio = AppThemeData(
    fondo: Color(0xFF0A0F1E),
    superficie: Color(0xFF141829),
    borde: Color(0xFF1E2545),
    accent: Color(0xFF8B5CF6),
    accent2: Color(0xFFA78BFA),
    rojoBright: Color(0xFFEC4899),
    textoPrim: Color(0xFFEFF6FF),
    textoSec: Color(0xFF94A3B8),
    textoApagado: Color(0xFF334155),
  );

  static const picante = AppThemeData(
    fondo: Color(0xFF120608),
    superficie: Color(0xFF1E0B0F),
    borde: Color(0xFF3D1520),
    accent: Color(0xFFFF2D55),
    accent2: Color(0xFFFF6B35),
    rojoBright: Color(0xFFFF0040),
    textoPrim: Color(0xFFFFF0F3),
    textoSec: Color(0xFFFFB3C1),
    textoApagado: Color(0xFF6B1A26),
  );

  static AppThemeData forNivel(NivelJuego n) {
    switch (n) {
      case NivelJuego.intermedio:
        return intermedio;
      case NivelJuego.picante:
        return picante;
      default:
        return normal;
    }
  }
}