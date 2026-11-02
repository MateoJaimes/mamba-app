# MAMBA

Aplicación Flutter para descubrir experiencias, explorar lugares, consultar reservas y administrar el perfil.

## Estructura

- `lib/core`: tema, navegación, red, errores, constantes y servicios comunes.
- `lib/features`: pantallas y lógica agrupadas por funcionalidad (`feed`, `experiences`, `map`, `calendar`, `profile`).
- `lib/shared`: widgets reutilizables entre funcionalidades.

La navegación principal usa GoRouter y conserva cada sección en un shell con barra inferior flotante. Feed, detalle de experiencia, búsqueda y perfil consultan Supabase cuando está configurado; en desarrollo, el catálogo de demostración queda como respaldo.

## Ejecutar

```sh
flutter pub get
flutter run
```

## Autenticación local

La app usa Supabase Auth con la llave pública de cliente (`sb_publishable_...`).
No incluyas una `sb_secret_...` ni una llave `service_role` en Flutter.

La configuración de ejecución de VS Code ya apunta al proyecto MAMBA. Para
ejecutar desde terminal, pasa la URL y la llave publicable del proyecto:

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

La carpeta hermana `mamba_db` conserva un esquema legado con `mamba.users.password_hash`;
la app usa el esquema Supabase de este repositorio y `auth.users`.

## Roles y confianza

- Toda cuenta autenticada puede explorar como turista.
- **Anfitrión de experiencias** es el nombre público para quien ofrece planes.
  La opción del registro crea una solicitud inicial (`draft`); no concede
  permisos ni habilita publicaciones. La aprobación y asignación del rol se
  hacen desde un entorno de confianza.
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

Supabase Auth está conectado para registro, inicio/cierre de sesión y
recuperación de contraseña. Android e iOS declaran `mamba://auth-callback`;
falta confirmar que esté en **Authentication → URL Configuration → Redirect URLs**
del proyecto para que los enlaces de correo vuelvan a la app.

## Base de datos Supabase

El esquema está en `supabase/schema.sql` y `supabase/migrations/`. Incluye
perfiles, roles, solicitudes de anfitrión, perfiles públicos, experiencias,
imágenes, reservas, reseñas, me gusta, comentarios, guardados, seguimientos y
notificaciones. Todas las tablas tienen RLS; los roles elevados no se asignan
desde el cliente. El proyecto tiene contenido de demostración para probar el
feed, perfiles y valoraciones.

El registro solicita nombres, apellidos, tipo y número de documento, fecha de
nacimiento, teléfono, correo y contraseña. Documento, fecha y teléfono se
guardan en `account_identity`, accesible solo por la cuenta dueña y sin campos
expuestos en los perfiles públicos.

La app usa la URL y la llave publicable del proyecto MAMBA en la configuración
de F5. Para ejecutar desde terminal, define ambas variables de Dart como se
muestra arriba. No incluyas llaves secretas en Flutter.

## Perfiles públicos de anfitrión

Desde el encabezado de una publicación se abre el perfil público del anfitrión.
La pestaña **Buscar** filtra por `@usuario`, nombre o ubicación. Con sesión, el
feed, los anfitriones, experiencias y reseñas se leen desde Supabase. Me gusta,
guardados, comentarios y seguimientos se persisten para cuentas autenticadas.
El catálogo local queda como respaldo cuando Supabase no está configurado.

Cada plan abre una ficha con fotos, descripción, duración, punto de encuentro,
incluye, requisitos, política de edad y precio. La inscripción distingue
personas adultas y menores, respeta planes solo para mayores o con edad mínima,
y solicita confirmación de acompañamiento cuando aplica. **Me apunto** guarda
una solicitud autenticada con fecha, número de personas y precio estimado; se
muestra como pendiente en la agenda. No es una reserva confirmada ni genera
cobro. Los pagos quedan fuera de alcance hasta elegir e integrar una pasarela.
