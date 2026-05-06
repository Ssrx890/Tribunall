# El Tribunal

Juego social estilo party game donde un grupo de personas entra en juicio y recibe un cargo y una sentencia aleatoria por ronda.

## Estructura

- `lib/main.dart`: punto de entrada mínimo.
- `lib/bootstrap.dart`: inicialización de preferencias, orientación y arranque de la app.
- `lib/app.dart`: `MaterialApp`, provider raíz y pantalla de error de arranque.
- `lib/state/app_state.dart`: estado global, lógica de juego y encapsulación de anuncios/compras.
- `lib/screens/`: pantallas principales.
- `lib/models/`: modelo del banco de contenido y nivel de juego.
- `lib/theme/`: tema visual por nivel.
- `lib/config/monetization_config.dart`: configuración centralizada de monetización.

## Monetización

La monetización quedó aislada en `lib/config/monetization_config.dart`.

- Los anuncios siguen usando IDs de prueba.
- Las compras in-app están desactivadas por ahora (`iapEnabled = false`).
- Cuando estén listos los valores reales, basta con actualizar ese archivo y volver a validar los flujos.

## Desarrollo

Comandos útiles:

```bash
flutter analyze
flutter test
flutter run
```

## Tests

La suite de widgets actual valida:

- Alta de acusados.
- Navegación al juicio.
- Desbloqueo directo del modo atrevido para usuarios premium.
- Estado visible de premium no configurado.
