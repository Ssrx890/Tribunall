import 'dart:convert';

import 'package:flutter/services.dart';

class Banco {
  final List<String> cN;
  final List<String> cI;
  final List<String> cP;
  final List<String> sN;
  final List<String> sI;
  final List<String> sP;

  const Banco({
    required this.cN,
    required this.cI,
    required this.cP,
    required this.sN,
    required this.sI,
    required this.sP,
  });

  static Future<Banco> cargar() async {
    try {
      final raw = await rootBundle.loadString('assets/banco.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      List<String> get(String key) =>
          (data[key] as List<dynamic>? ?? []).cast<String>();
      return Banco(
        cN: get('cargos_normal'),
        cI: get('cargos_intermedio'),
        cP: get('cargos_picante'),
        sN: get('sentencias_normal'),
        sI: get('sentencias_intermedio'),
        sP: get('sentencias_picante'),
      );
    } catch (e) {
      throw Exception('Error al cargar los datos del juego: $e');
    }
  }
}