import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nivel_juego.dart';
import '../state/app_state.dart';
import '../theme/app_theme_data.dart';

class PantallaJuicio extends StatefulWidget {
  const PantallaJuicio({super.key});

  @override
  State<PantallaJuicio> createState() => _PantallaJuicioState();
}

class _PantallaJuicioState extends State<PantallaJuicio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _escalaAnim;

  String _acusado = '';
  String _cargo = '';
  String _sentencia = '';
  bool _mostrandoSentencia = false;
  int _tiempoRestante = 0;
  Timer? _timer;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _escalaAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _generarCaso());
  }

  void _generarCaso() {
    final s = context.read<AppState>();
    final List<String> cargosPool;
    final List<String> sentenciasPool;

    switch (s.nivel) {
      case NivelJuego.intermedio:
        cargosPool = [...s.banco.cN, ...s.banco.cI];
        sentenciasPool = [...s.banco.sN, ...s.banco.sI];
        break;
      case NivelJuego.picante:
        cargosPool = [...s.banco.cN, ...s.banco.cI, ...s.banco.cP];
        sentenciasPool = [...s.banco.sN, ...s.banco.sI, ...s.banco.sP];
        break;
      case NivelJuego.normal:
        cargosPool = s.banco.cN;
        sentenciasPool = s.banco.sN;
        break;
    }

    if (s.acusados.isEmpty || cargosPool.isEmpty || sentenciasPool.isEmpty) {
      return;
    }

    final acusado = s.acusados[_rng.nextInt(s.acusados.length)];
    final cargo = cargosPool[_rng.nextInt(cargosPool.length)];
    final sentencia = sentenciasPool[_rng.nextInt(sentenciasPool.length)];

    setState(() {
      _acusado = acusado;
      _cargo = cargo;
      _sentencia = sentencia;
      _mostrandoSentencia = false;
      _tiempoRestante = s.tiempoConfigurado;
    });

    _animCtrl.forward(from: 0);
    _iniciarTimer(s);
    s.incrementarContador();

    if (!s.esPremium && s.contadorJuicios % 5 == 0 && s.contadorJuicios > 0) {
      s.mostrarInterstitial();
    }
  }

  void _iniciarTimer(AppState s) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_tiempoRestante <= 1) {
        timer.cancel();
        if (!_mostrandoSentencia) _revelarSentencia();
      } else {
        setState(() => _tiempoRestante--);
      }
    });
  }

  void _revelarSentencia() {
    setState(() {
      _mostrandoSentencia = true;
    });
    _animCtrl.forward(from: 0);
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final th = AppThemeData.forNivel(s.nivel);

    late final String nivelLabel;
    late final String nivelEmoji;

    switch (s.nivel) {
      case NivelJuego.intermedio:
        nivelLabel = 'ATREVIDO';
        nivelEmoji = '🌙';
        break;
      case NivelJuego.picante:
        nivelLabel = 'PICANTE';
        nivelEmoji = '🔥';
        break;
      case NivelJuego.normal:
        nivelLabel = 'NORMAL';
        nivelEmoji = '⚖️';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: th.fondo,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: th.textoSec, size: 18),
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
          ),
          title: Text(
            'EL TRIBUNAL',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 14,
              color: th.accent,
              letterSpacing: 3,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: th.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: th.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$nivelEmoji $nivelLabel',
                style: TextStyle(
                  fontSize: 10,
                  color: th.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTimer(th),
                const SizedBox(height: 24),
                Expanded(child: _buildCard(th)),
                const SizedBox(height: 24),
                _buildBotones(s, th),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimer(AppThemeData th) {
    final isUrgent = _tiempoRestante <= 5 && !_mostrandoSentencia;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isUrgent
                ? th.rojoBright.withValues(alpha: 0.15)
                : th.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUrgent ? th.rojoBright : th.borde,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: isUrgent ? th.rojoBright : th.textoSec,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _mostrandoSentencia ? '¡SENTENCIA!' : '${_tiempoRestante}s',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  color: isUrgent ? th.rojoBright : th.textoSec,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AppThemeData th) {
    return ScaleTransition(
      scale: _escalaAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: th.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: th.borde, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: th.accent.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _mostrandoSentencia
            ? _buildSentenciaContent(th)
            : _buildCargoContent(th),
      ),
    );
  }

  Widget _buildCargoContent(AppThemeData th) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: th.rojoBright.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: th.rojoBright.withValues(alpha: 0.4)),
          ),
          child: Text(
            'EL ACUSADO',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 10,
              letterSpacing: 2,
              color: th.rojoBright,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _acusado,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: th.textoPrim,
          ),
        ),
        const SizedBox(height: 24),
        Divider(color: th.borde, thickness: 1),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: th.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: th.accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            'SE LE ACUSA DE...',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 10,
              letterSpacing: 2,
              color: th.accent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _cargo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: th.textoSec,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSentenciaContent(AppThemeData th) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: th.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: th.accent.withValues(alpha: 0.5)),
          ),
          child: Text(
            '⚖️  SENTENCIA DICTADA',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 10,
              letterSpacing: 2,
              color: th.accent,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _acusado,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: th.textoPrim,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'deberá...',
          style: TextStyle(color: th.textoSec, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Divider(color: th.borde),
        const SizedBox(height: 16),
        Text(
          _sentencia,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            color: th.accent,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBotones(AppState s, AppThemeData th) {
    if (!_mostrandoSentencia) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _revelarSentencia,
          style: ElevatedButton.styleFrom(
            backgroundColor: th.rojoBright,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            textStyle: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          child: const Text('⚖️  DICTAR SENTENCIA'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: th.textoSec,
              side: BorderSide(color: th.borde),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Salir'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _generarCaso,
            style: ElevatedButton.styleFrom(
              backgroundColor: th.accent,
              foregroundColor: th.fondo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
              textStyle: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            child: const Text('SIGUIENTE CASO ⟶'),
          ),
        ),
      ],
    );
  }
}