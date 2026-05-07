import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme_data.dart';

Future<void> mostrarOpciones(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OpcionesSheet(),
  );
}

class _OpcionesSheet extends StatelessWidget {
  const _OpcionesSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final th = AppThemeData.forNivel(s.nivel);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: th.fondo,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: th.borde, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: th.textoApagado,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'OPCIONES',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: th.textoPrim,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // ── Preferencias ──────────────────────────────────
            _SectionLabel(label: 'PREFERENCIAS', th: th),
            const SizedBox(height: 8),
            _ToggleTile(
              icon: s.musicaActiva ? Icons.music_note_rounded : Icons.music_off_rounded,
              titulo: 'Música',
              subtitulo: s.musicaActiva ? 'Activada' : 'Desactivada',
              valor: s.musicaActiva,
              th: th,
              onChange: (v) => s.setMusica(v),
            ),
            const SizedBox(height: 8),
            _ToggleTile(
              icon: s.sonidoActivo ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              titulo: 'Sonido',
              subtitulo: s.sonidoActivo ? 'Activado' : 'Desactivado',
              valor: s.sonidoActivo,
              th: th,
              onChange: (v) => s.setSonido(v),
            ),
            const SizedBox(height: 8),
            _ToggleTile(
              icon: s.vibracionActiva
                  ? Icons.vibration_rounded
                  : Icons.phone_android_rounded,
              titulo: 'Vibración',
              subtitulo: s.vibracionActiva ? 'Activada' : 'Desactivada',
              valor: s.vibracionActiva,
              th: th,
              onChange: (v) => s.setVibracion(v),
            ),

            const SizedBox(height: 20),

            // ── Partida ───────────────────────────────────────
            _SectionLabel(label: 'PARTIDA', th: th),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.people_outline_rounded,
              titulo: 'Borrar jugadores',
              subtitulo: s.acusados.isEmpty
                  ? 'No hay jugadores'
                  : '${s.acusados.length} jugador${s.acusados.length == 1 ? '' : 'es'} en lista',
              th: th,
              destructivo: true,
              onTap: s.acusados.isEmpty
                  ? null
                  : () async {
                      final ok = await _confirmar(
                        context,
                        th,
                        titulo: 'Borrar jugadores',
                        mensaje:
                            '¿Eliminar a todos los jugadores de la lista?',
                        labelConfirmar: 'Borrar',
                      );
                      if (ok == true && context.mounted) {
                        context.read<AppState>().limpiarJugadores();
                      }
                    },
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.menu_book_outlined,
              titulo: 'Ver tutorial',
              subtitulo: 'Vuelve a mostrar el tutorial al iniciar',
              th: th,
              onTap: () async {
                await s.resetearTutorial();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Tutorial activado: aparecerá al iniciar la próxima partida.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),

            if (s.compraPicanteDisponible) ...[
              const SizedBox(height: 20),
              _SectionLabel(label: 'COMPRAS', th: th),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.restore_rounded,
                titulo: 'Restaurar compras',
                subtitulo: s.esPremium
                    ? 'Ya tienes Premium activo'
                    : 'Recupera compras anteriores',
                th: th,
                onTap: s.esPremium
                    ? null
                    : () {
                        s.restaurarCompras();
                        Navigator.of(context).pop();
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmar(
    BuildContext context,
    AppThemeData th, {
    required String titulo,
    required String mensaje,
    required String labelConfirmar,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: th.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          titulo,
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: th.textoPrim,
          ),
        ),
        content: Text(
          mensaje,
          style: TextStyle(color: th.textoSec, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: th.textoSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              labelConfirmar,
              style: const TextStyle(color: Color(0xFFFF4D6D)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppThemeData th;

  const _SectionLabel({required this.label, required this.th});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Oswald',
        fontSize: 11,
        letterSpacing: 1.5,
        color: th.textoApagado,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final bool valor;
  final AppThemeData th;
  final ValueChanged<bool> onChange;

  const _ToggleTile({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.th,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: th.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: th.borde),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: Icon(icon, color: th.accent, size: 22),
        title: Text(
          titulo,
          style: TextStyle(
            color: th.textoPrim,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitulo,
            style: TextStyle(color: th.textoSec, fontSize: 12)),
        value: valor,
        activeThumbColor: th.accent,
        onChanged: onChange,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final AppThemeData th;
  final VoidCallback? onTap;
  final bool destructivo;

  const _ActionTile({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.th,
    this.onTap,
    this.destructivo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? th.textoApagado
        : destructivo
            ? const Color(0xFFFF4D6D)
            : th.textoPrim;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: th.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: th.borde),
          ),
          child: Row(
            children: [
              Icon(icon, color: onTap == null ? th.textoApagado : th.accent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(color: th.textoSec, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: th.textoApagado, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
