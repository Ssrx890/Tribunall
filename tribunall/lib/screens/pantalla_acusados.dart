import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show AdWidget;
import 'package:provider/provider.dart';

import '../models/nivel_juego.dart';
import '../state/app_state.dart';
import '../theme/app_theme_data.dart';
import 'pantalla_juicio.dart';

class PantallaAcusados extends StatefulWidget {
  const PantallaAcusados({super.key});

  @override
  State<PantallaAcusados> createState() => _PantallaAcusadosState();
}

class _PantallaAcusadosState extends State<PantallaAcusados> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _agregar(AppState s) {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    if (texto.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es demasiado largo (máx. 50 caracteres).'),
        ),
      );
      return;
    }
    s.agregarAcusado(texto);
    _ctrl.clear();
  }

  Future<void> _onIntermedio(AppState s) async {
    if (s.esIntermedio) {
      s.setNivel(NivelJuego.normal);
      return;
    }

    if (s.esPremium) {
      s.setNivel(NivelJuego.intermedio);
      return;
    }

    if (!s.puedeDesbloquearIntermedio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo atrevido no disponible en este momento.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => const _ModoAnuncioDialog(),
    );
    if (confirmar != true) return;

    final ganado = await s.mostrarRewardedYEsperar();
    if (ganado && mounted) {
      s.setNivel(NivelJuego.intermedio);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el anuncio. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  Future<void> _onPicante(AppState s) async {
    if (s.esPremium) {
      s.setNivel(s.esPicante ? NivelJuego.normal : NivelJuego.picante);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PremiumModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final th = AppThemeData.forNivel(s.nivel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: th.fondo,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              if (s.anunciosActivos && s.bannerCargado && s.bannerAd != null)
                SizedBox(
                  height: s.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: s.bannerAd!),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  children: [
                    Text(
                      '⚖️',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EL TRIBUNAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: th.accent,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nadie es inocente aquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: th.textoSec,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildModeSelector(s, th),
                    const SizedBox(height: 24),
                    _buildTiempoSelector(s, th),
                    const SizedBox(height: 24),
                    _buildAgregarAcusado(s, th),
                    const SizedBox(height: 16),
                    ...s.acusados.asMap().entries.map(
                          (e) => _buildChip(e.value, e.key, s, th),
                        ),
                    const SizedBox(height: 24),
                    _buildBotonIniciar(s, th),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(AppState s, AppThemeData th) {
    return Container(
      decoration: BoxDecoration(
        color: th.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.borde),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MODO DE JUEGO',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 11,
              letterSpacing: 2,
              color: th.textoSec,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ModeButton(
                emoji: '⚖️',
                label: 'NORMAL',
                sublabel: 'GRATIS',
                selected: s.nivel == NivelJuego.normal,
                color: const Color(0xFFFFBD2E),
                onTap: () => s.setNivel(NivelJuego.normal),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                emoji: '🌙',
                label: 'ATREVIDO',
                sublabel: s.esPremium ? 'PREMIUM ✓' : 'VER ANUNCIO',
                selected: s.nivel == NivelJuego.intermedio,
                color: const Color(0xFF8B5CF6),
                onTap: () => _onIntermedio(s),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                emoji: '🔥',
                label: 'PICANTE',
                sublabel: s.esPremium
                    ? 'PREMIUM ✓'
                    : (s.compraPicanteDisponible ? '\$1.99' : 'PROXIMAMENTE'),
                selected: s.nivel == NivelJuego.picante,
                color: const Color(0xFFFF2D55),
                onTap: () => _onPicante(s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiempoSelector(AppState s, AppThemeData th) {
    return Container(
      decoration: BoxDecoration(
        color: th.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.borde),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('⏱️', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            'Tiempo por ronda',
            style: TextStyle(color: th.textoPrim, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          _TiempoBtn(
            label: '−',
            color: th.accent,
            onTap: s.tiempoConfigurado > 5
                ? () => s.setTiempo(s.tiempoConfigurado - 5)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            '${s.tiempoConfigurado}s',
            style: TextStyle(
              color: th.accent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          _TiempoBtn(
            label: '+',
            color: th.accent,
            onTap: s.tiempoConfigurado < 120
                ? () => s.setTiempo(s.tiempoConfigurado + 5)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAgregarAcusado(AppState s, AppThemeData th) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: TextStyle(color: th.textoPrim),
            cursorColor: th.accent,
            decoration: InputDecoration(
              hintText: 'Nombre del acusado',
              hintStyle: TextStyle(color: th.textoApagado),
              filled: true,
              fillColor: th.superficie,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: th.borde),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: th.borde),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: th.accent),
              ),
            ),
            onSubmitted: (_) => _agregar(s),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _agregar(s),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: th.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add, color: th.fondo, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String nombre, int index, AppState s, AppThemeData th) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: th.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: th.borde),
      ),
      child: Row(
        children: [
          Text('👤', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nombre,
              style: TextStyle(color: th.textoPrim, fontSize: 15),
            ),
          ),
          GestureDetector(
            onTap: () => s.removerAcusado(index),
            child: Icon(Icons.close, color: th.textoSec, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonIniciar(AppState s, AppThemeData th) {
    final canStart = s.acusados.isNotEmpty;
    late final String label;

    switch (s.nivel) {
      case NivelJuego.intermedio:
        label = '🌙  INICIAR JUICIO ATREVIDO';
        break;
      case NivelJuego.picante:
        label = '🔥  INICIAR JUICIO PICANTE';
        break;
      case NivelJuego.normal:
        label = '⚖️  INICIAR JUICIO';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canStart
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaJuicio()),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart ? th.accent : th.textoApagado,
          foregroundColor: th.fondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
          elevation: canStart ? 6 : 0,
        ),
        child: Text(label),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: selected ? color : color.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 8,
                  color: selected
                      ? color.withValues(alpha: 0.8)
                      : color.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TiempoBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _TiempoBtn({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap != null ? color : color.withValues(alpha: 0.3),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModoAnuncioDialog extends StatelessWidget {
  const _ModoAnuncioDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141829),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '🌙 Modo Atrevido',
        style: TextStyle(
          fontFamily: 'Cinzel',
          color: Color(0xFF8B5CF6),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: const Text(
        'Desbloquea preguntas más atrevidas e íntimas durante esta sesión.\n\n'
        'Para activarlo, verás un anuncio breve. ¡Así de fácil!',
        style: TextStyle(color: Color(0xFFEFF6FF), height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Ver Anuncio', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _PremiumModal extends StatelessWidget {
  const _PremiumModal();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final compraDisponible = s.compraPicanteDisponible;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E0B0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D1520),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text('🔥', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text(
                'MODO PICANTE',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF2D55),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desbloqueo permanente para adultos',
                style: TextStyle(color: Color(0xFFFFB3C1), fontSize: 13),
              ),
              const SizedBox(height: 24),
              ...[
                '🔥 +130 cargos y sentencias explícitas para adultos',
                '🚫 Sin anuncios en ningún modo',
                '🌙 Modo Atrevido siempre desbloqueado',
                '♾️ Pago único, sin suscripción',
              ].map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Text(f.substring(0, 2), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f.substring(2).trim(),
                          style: const TextStyle(
                            color: Color(0xFFFFF0F3),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!compraDisponible) ...[
                const SizedBox(height: 12),
                const Text(
                  'La compra premium aún no está configurada. Cuando esté lista, se activará aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFFFB3C1), height: 1.4),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: compraDisponible && !s.cargandoPago
                      ? () => s.comprarPicante()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2D55),
                    disabledBackgroundColor: const Color(0xFF6B1A26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: s.cargandoPago
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          compraDisponible
                              ? 'DESBLOQUEAR · \$1.99'
                              : 'PROXIMAMENTE',
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: compraDisponible && !s.cargandoPago
                    ? () => s.restaurarCompras()
                    : null,
                child: const Text(
                  'Restaurar compra',
                  style: TextStyle(color: Color(0xFFFFB3C1), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}