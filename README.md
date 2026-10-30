# MAMBA

Aplicación Flutter para descubrir experiencias, explorar lugares, consultar reservas y administrar el perfil.

## Estructura

- `lib/core`: tema, navegación, red, errores, constantes y servicios comunes.
- `lib/features`: pantallas y lógica agrupadas por funcionalidad (`feed`, `experiences`, `map`, `calendar`, `profile`).
- `lib/shared`: widgets reutilizables entre funcionalidades.

La navegación principal usa GoRouter y conserva cada sección en un shell con barra inferior flotante. El feed y el repositorio de experiencias todavía contienen datos de demostración o fuentes remotas pendientes.

## Ejecutar

```sh
flutter pub get
flutter run
```

## Autenticación local

La app usa Supabase Auth con la llave pública de cliente (`sb_publishable_...`).
No incluyas una `sb_secret_...` ni una llave `service_role` en Flutter.

Para probar la conexión en desarrollo:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_<key>
```

Sin configuración, el modo debug permite previsualizar las pantallas actuales.
Los builds de release requieren configuración y bloquean el acceso al producto
hasta que exista una sesión autenticada. El registro puede requerir confirmar
el correo según los ajustes de Auth del proyecto. Para confirmar correo y
restablecer contraseña desde el móvil, agrega `mamba://auth-callback` a la lista
de Redirect URLs permitidas en Supabase Auth. Android e iOS ya declaran ese
esquema para abrir MAMBA desde los enlaces de autenticación.

La carpeta hermana `mamba_db` aún contiene un esquema legado con
`mamba.users.password_hash`; no lo conectes al cliente ni lo publiques hasta
migrar la identidad a `auth.users` y definir RLS para las tablas expuestas.

## Roles y confianza

- Toda cuenta autenticada puede explorar como turista.
- **Anfitrión de experiencias** es el nombre público para quien ofrece planes.
  La opción del registro solo expresa interés; no concede permisos ni habilita
  publicaciones. La solicitud formal, verificación y estados (`pending_review`,
  `approved`, `rejected`, `suspended`) requieren persistencia y revisión desde
  un backend seguro.
- Administración es un acceso interno de backoffice. No aparece en el registro
  público y sus permisos deben asignarse desde el servidor, nunca desde
  `user_metadata`.
- Reservas y pagos son conceptos separados. La pasarela y el cobro están fuera
  de alcance hasta que se decida el proveedor y se implemente su backend.

## Calificaciones

La interfaz usa frases colombianas para calificar la experiencia (`No fue lo
mío`, `Buen parche`, `Súper parche`, `Planazo`, `¡Una chimba!`) y, de manera
independiente, el servicio del anfitrión (`No volvería`, `Atención normal`,
`Buen anfitrión`, `Muy buena energía`, `Se lució`). Los valores numéricos de 1 a
5 se conservan para agregados y filtros, no para mostrar estrellas. En
producción, solo una reserva completada debe permitir reseñar; moderación y
reportes requieren backend.

La conexión de Supabase aún no está configurada para MAMBA; la selección de
interés y las tarjetas del feed son presentación/datos de demostración, no un
flujo persistido de solicitudes ni reseñas.

## Perfiles públicos de anfitrión

Desde el encabezado de una publicación se abre el perfil público del anfitrión.
La pestaña **Buscar** filtra por `@usuario`, nombre o ubicación. El perfil
muestra foto, biografía, ubicación, valoración de planes, valoración de
servicio del anfitrión y una cuadrícula de sus experiencias. Feed, búsqueda y
perfil comparten el catálogo de demostración en
`lib/features/hosts/data/demo_host_catalog.dart`; los seguimientos y el catálogo
no se sincronizan ni persisten mientras no exista backend.

Cada plan abre una ficha con fotos, descripción, duración, punto de encuentro,
incluye, requisitos, política de edad y precio. La inscripción distingue
personas adultas y menores, respeta planes solo para mayores o con edad mínima,
y solicita confirmación de acompañamiento cuando aplica. **Me apunto** guarda en el dispositivo una
solicitud local con fecha y número de personas; aparece en la agenda como
pendiente. No es una reserva confirmada ni genera cobro. La persistencia local
está en `lib/features/bookings/data/local_booking_store.dart` y debe migrarse a
un backend autenticado antes de producción.
