import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nivel_juego.dart';
import '../models/bancos.dart';
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
  String _juez = '';
  String _cargo = '';
  String _sentencia = '';
  bool _mostrandoSentencia = false;
  bool _absuelto = false;
  bool _sinDatos = false;
  CartaDefensa? _cartaDefensa;
  int _tiempoRestante = 0;
  Timer? _timer;
  final _rng = Random();
  // Cada caso incrementa _generacion. El addPostFrameCallback verifica que
  // sigue siendo el callback activo antes de arrancar animación y timer.
  int _generacion = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _escalaAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = context.read<AppState>();
      if (!s.tutorialVisto) {
        await _mostrarTutorial();
      }
      if (mounted) _generarCaso();
    });
  }

  Future<void> _mostrarTutorial() async {
    final s = context.read<AppState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TutorialDialog(),
    );
    await s.marcarTutorialVisto();
  }

  void _generarCaso() {
    if (!mounted) return;
    _timer?.cancel();
    _timer = null;
    final gen = ++_generacion;

    final s = context.read<AppState>();
    final banco = s.bancoSeleccionado;
    final List<String> cargosPool;
    final List<String> sentenciasPool;

    switch (s.nivel) {
      case NivelJuego.intermedio:
        cargosPool = [...banco.cN, ...banco.cI];
        sentenciasPool = [...banco.sN, ...banco.sI];
        break;
      case NivelJuego.picante:
        cargosPool = [...banco.cN, ...banco.cI, ...banco.cP];
        sentenciasPool = [...banco.sN, ...banco.sI, ...banco.sP];
        break;
      case NivelJuego.normal:
        cargosPool = banco.cN;
        sentenciasPool = banco.sN;
        break;
    }

    if (s.acusados.length < 2 || cargosPool.isEmpty || sentenciasPool.isEmpty) {
      setState(() => _sinDatos = true);
      return;
    }

    final jugadores = s.acusados.toList();
    final juezIdx = _rng.nextInt(jugadores.length);
    final juez = jugadores[juezIdx];
    final restantes = [...jugadores]..removeAt(juezIdx);
    if (restantes.isEmpty) {
      setState(() => _sinDatos = true);
      return;
    }
    final acusado = restantes[_rng.nextInt(restantes.length)];
    final cargo = cargosPool[_rng.nextInt(cargosPool.length)];
    final sentencia = sentenciasPool[_rng.nextInt(sentenciasPool.length)];

    CartaDefensa? carta;
    if (s.cartasDefensa.isNotEmpty) {
      carta = s.cartasDefensa[_rng.nextInt(s.cartasDefensa.length)];
    }

    s.incrementarContador();
    final shouldShowAd =
        !s.esPremium && s.contadorJuicios % 5 == 0 && s.contadorJuicios > 0;

    setState(() {
      _sinDatos = false;
      _juez = juez;
      _acusado = acusado;
      _cargo = cargo;
      _sentencia = sentencia;
      _cartaDefensa = carta;
      _mostrandoSentencia = false;
      _absuelto = false;
      _tiempoRestante = s.tiempoConfigurado;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _generacion) return;
      _animCtrl.stop();
      _animCtrl.forward(from: 0);
      _iniciarTimer(context.read<AppState>());
      if (shouldShowAd) context.read<AppState>().mostrarInterstitial();
    });
  }

  void _iniciarTimer(AppState s) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_tiempoRestante <= 1) {
        t.cancel();
        _timer = null;
        if (!_mostrandoSentencia && !_absuelto) _revelarSentencia();
      } else {
        setState(() => _tiempoRestante--);
      }
    });
  }

  void _revelarSentencia() {
    if (!mounted || _mostrandoSentencia || _absuelto) return;
    _timer?.cancel();
    _timer = null;
    setState(() { _mostrandoSentencia = true; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { _animCtrl.stop(); _animCtrl.forward(from: 0); }
    });
  }

  void _librar() {
    if (!mounted || _absuelto || _mostrandoSentencia) return;
    _timer?.cancel();
    _timer = null;
    setState(() { _absuelto = true; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { _animCtrl.stop(); _animCtrl.forward(from: 0); }
    });
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
              fontFamily: 'Oswald',
              fontSize: 16,
              color: th.accent,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
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
    final isUrgent = _tiempoRestante <= 5 &&
        !_mostrandoSentencia &&
        !_absuelto;
    const verdeLibre = Color(0xFF4ADE80);

    final String timerLabel;
    final Color timerColor;
    final Color timerBg;
    final Color timerBorder;

    if (_absuelto) {
      timerLabel = '¡LIBRE!';
      timerColor = verdeLibre;
      timerBg = verdeLibre.withValues(alpha: 0.12);
      timerBorder = verdeLibre;
    } else if (_mostrandoSentencia) {
      timerLabel = '¡SENTENCIA!';
      timerColor = th.textoSec;
      timerBg = th.superficie;
      timerBorder = th.borde;
    } else if (isUrgent) {
      timerLabel = '${_tiempoRestante}s';
      timerColor = th.rojoBright;
      timerBg = th.rojoBright.withValues(alpha: 0.15);
      timerBorder = th.rojoBright;
    } else {
      timerLabel = '${_tiempoRestante}s';
      timerColor = th.textoSec;
      timerBg = th.superficie;
      timerBorder = th.borde;
    }

    return Column(
      children: [
        if (_juez.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👑 ', style: TextStyle(fontSize: 13)),
                Text(
                  'Juez: $_juez',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 13,
                    color: th.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: timerBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: timerBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _absuelto
                        ? Icons.check_circle_outline_rounded
                        : Icons.timer_outlined,
                    color: timerColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timerLabel,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: timerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(AppThemeData th) {
    if (_sinDatos) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: th.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: th.borde, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No hay datos suficientes para generar un caso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: th.textoPrim,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vuelve y agrega acusados o revisa el banco de contenidos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: th.textoSec, height: 1.5),
            ),
          ],
        ),
      );
    }

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
        child: _absuelto
            ? _buildAbsueltoContent(th)
            : _mostrandoSentencia
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
              fontFamily: 'Oswald',
              fontSize: 11,
              letterSpacing: 1.5,
              color: th.rojoBright,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _acusado,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 34,
            fontWeight: FontWeight.w700,
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
              fontFamily: 'Oswald',
              fontSize: 11,
              letterSpacing: 1.5,
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
        if (_cartaDefensa != null) ...[  
          const SizedBox(height: 20),
          Divider(color: th.borde, thickness: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _mostrarCarta(th),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_cartaDefensa!.emoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    _cartaDefensa!.titulo,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.info_outline,
                      color: Color(0xFF7C3AED), size: 14),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarCarta(AppThemeData th) {
    if (_cartaDefensa == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_cartaDefensa!.emoji,
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                _cartaDefensa!.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _cartaDefensa!.descripcion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'ENTENDIDO',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbsueltoContent(AppThemeData th) {
    const verde = Color(0xFF4ADE80);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: verde.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: verde.withValues(alpha: 0.5)),
          ),
          child: const Text(
            '✅  ¡LIBRE DE CARGOS!',
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: 11,
              letterSpacing: 1.5,
              color: verde,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _acusado,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: verde,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ha convencido al juez',
          style: TextStyle(color: th.textoSec, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Divider(color: th.borde),
        const SizedBox(height: 16),
        Text(
          'El acusado se defiende con éxito y el juez $_juez dicta su inocencia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: th.textoPrim,
            height: 1.6,
            fontWeight: FontWeight.w500,
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
              fontFamily: 'Oswald',
              fontSize: 11,
              letterSpacing: 1.5,
              color: th.accent,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _acusado,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 26,
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
    if (_sinDatos) {
      return SizedBox(
        width: double.infinity,
        height: 52,
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
          ),
          child: const Text('Volver'),
        ),
      );
    }

    if (!_mostrandoSentencia && !_absuelto) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _librar,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4ADE80),
                side: const BorderSide(color: Color(0xFF4ADE80)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              child: const Text('✅ LIBRAR'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _revelarSentencia,
              style: ElevatedButton.styleFrom(
                backgroundColor: th.rojoBright,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                textStyle: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              child: const Text('⚖️  DICTAR SENTENCIA'),
            ),
          ),
        ],
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
                fontFamily: 'Oswald',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            child: const Text('SIGUIENTE CASO ⟶'),
          ),
        ),
      ],
    );
  }
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog();

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _pagina = 0;

  static const _pasos = [
    _TutorialPaso(
      emoji: '\u2696\ufe0f',
      titulo: 'Bienvenido al Tribunal',
      descripcion:
          'Un juego de mesa para grupos. Cada ronda, uno es el juez y otro se sienta en el banquillo de los acusados.',
    ),
    _TutorialPaso(
      emoji: '\ud83c\udfb2',
      titulo: 'Roles al azar',
      descripcion:
          'Cada ronda el juego elige automáticamente quién es el \u00a0👑\u00a0Juez y quién es el \u00a0👤\u00a0Acusado. \u00a1Nadie se libra!',
    ),
    _TutorialPaso(
      emoji: '\ud83d�',
      titulo: 'El cargo',
      descripcion:
          'El acusado recibe un cargo absurdo o picante. El grupo debate si es culpable mientras corre el tiempo.',
    ),
    _TutorialPaso(
      emoji: '\u23f1\ufe0f',
      titulo: 'El tiempo',
      descripcion:
          'Cuando el tiempo se acaba (o pulsas el botón) el juez dicta sentencia. \u00a1La sentencia es ley!',
    ),
    _TutorialPaso(
      emoji: '\ud83c\udf89',
      titulo: '\u00a1A jugar!',
      descripcion:
          'Minimum 3 jugadores. Cuantos más, mejor. Pulsa \u00abSIGUIENTE CASO\u00bb para rotar de ronda en ronda.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pagina];
    final esUltimo = _pagina == _pasos.length - 1;
    final th = AppThemeData.forNivel(NivelJuego.normal);

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // indicador de paginación
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pasos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _pagina ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _pagina
                        ? th.accent
                        : th.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(paso.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              paso.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              paso.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                if (_pagina > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _pagina--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: th.textoSec,
                        side: BorderSide(color: th.borde),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Atrás'),
                    ),
                  ),
                if (_pagina > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (esUltimo) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _pagina++);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: th.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    child: Text(esUltimo ? '\u00a1EMPEZAR!' : 'SIGUIENTE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPaso {
  final String emoji;
  final String titulo;
  final String descripcion;

  const _TutorialPaso({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
  });
}