import 'dart:convert';

import 'package:flutter/services.dart';

class CartaDefensa {
  final String id;
  final String emoji;
  final String titulo;
  final String descripcion;

  const CartaDefensa({
    required this.id,
    required this.emoji,
    required this.titulo,
    required this.descripcion,
  });

  factory CartaDefensa.fromJson(Map<String, dynamic> json) => CartaDefensa(
        id: json['id'] as String,
        emoji: json['emoji'] as String,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String,
      );
}

class BancoTematico {
  final String id;
  final String nombre;
  final String emoji;
  final String descripcion;
  final int minJugadores;
  final List<String> cN;
  final List<String> sN;
  final List<String> cI;
  final List<String> sI;
  final List<String> cP;
  final List<String> sP;

  const BancoTematico({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.descripcion,
    required this.minJugadores,
    required this.cN,
    required this.sN,
    required this.cI,
    required this.sI,
    required this.cP,
    required this.sP,
  });

  bool get tieneIntermedio => cI.isNotEmpty;
  bool get tienePicante => cP.isNotEmpty;

  factory BancoTematico.fromJson(Map<String, dynamic> json) {
    List<String> get(String key) =>
        (json[key] as List<dynamic>? ?? []).cast<String>();
    return BancoTematico(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      emoji: json['emoji'] as String,
      descripcion: json['descripcion'] as String,
      minJugadores: (json['minJugadores'] as num?)?.toInt() ?? 2,
      cN: get('cargos_normal'),
      sN: get('sentencias_normal'),
      cI: get('cargos_intermedio'),
      sI: get('sentencias_intermedio'),
      cP: get('cargos_picante'),
      sP: get('sentencias_picante'),
    );
  }
}

class Bancos {
  final List<BancoTematico> bancos;
  final List<CartaDefensa> cartasDefensa;

  const Bancos({required this.bancos, required this.cartasDefensa});

  BancoTematico get porDefecto => bancos.first;

  BancoTematico? porId(String id) {
    try {
      return bancos.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Bancos> cargar() async {
    try {
      final raw = await rootBundle.loadString('assets/bancos.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final bancosJson = data['bancos'] as List<dynamic>? ?? [];
      final cartasJson = data['cartas_defensa'] as List<dynamic>? ?? [];

      return Bancos(
        bancos: bancosJson
            .cast<Map<String, dynamic>>()
            .map(BancoTematico.fromJson)
            .toList(),
        cartasDefensa: cartasJson
            .cast<Map<String, dynamic>>()
            .map(CartaDefensa.fromJson)
            .toList(),
      );
    } catch (e) {
      throw Exception('Error al cargar los bancos de datos: $e');
    }
  }
}
