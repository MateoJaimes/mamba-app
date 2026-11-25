# MAPO

Aplicación Flutter para descubrir experiencias, explorar lugares, consultar reservas y administrar el perfil. El backend es NestJS, en `backend/`, y Supabase proporciona Auth y Postgres.

## Estructura

- `lib/core`: tema, navegación, red, errores, constantes y servicios comunes.
- `lib/features`: pantallas y lógica agrupadas por funcionalidad (`feed`, `experiences`, `map`, `calendar`, `profile`).
- `lib/shared`: widgets reutilizables entre funcionalidades.
- `backend/src`: API NestJS, acceso autenticado a datos y correo.
- `backend/templates`: seis plantillas HTML de autenticación con la identidad MAPO.
- `backend/.env.local`: configuración privada local, excluida de Git. Completar `SMTP_PASSWORD` con una contraseña de aplicación de Gmail.

La navegación usa GoRouter y conserva cada sección con barra inferior flotante. Flutter consulta exclusivamente la URL de NestJS para autenticación y datos. El SDK cliente mantiene la sesión y serializa peticiones; NestJS inyecta la llave real de Supabase. El catálogo local solo se usa sin configuración, nunca para ocultar errores de red.

## Ejecutar

```sh
flutter pub get
flutter run --dart-define-from-file=config/mapo.json
```

## Autenticación local

La app usa Supabase Auth detrás de NestJS. La APK contiene la URL pública de la API y un identificador de transporte sin privilegios. La llave del proveedor y SMTP permanecen en el backend. NestJS conserva el JWT del usuario al consultar datos: RLS valida cada operación sin usar una llave que salte permisos.

La configuración de ejecución de VS Code ya apunta al proyecto MAPO. Para
ejecutar desde terminal:

```sh
flutter run --dart-define-from-file=config/mapo.json
```

Sin configuración, el modo debug permite previsualizar las pantallas actuales.
Los builds de release requieren configuración y bloquean el acceso al producto
hasta que exista una sesión autenticada. El registro puede requerir confirmar
el correo según los ajustes de Auth del proyecto. Para confirmar correo y
restablecer contraseña desde el móvil, agrega `mapo://auth-callback` a la lista
de Redirect URLs permitidas en Supabase Auth. Android e iOS ya declaran ese
esquema para abrir MAPO desde los enlaces de autenticación.

El backend local usa `MAPO_APP` en Supabase (`affhiuzxhejwolcoivnf`) mediante `backend/.env.local`. El esquema, los catálogos y tres experiencias de demostración están disponibles en ese proyecto. La configuración de la APK en `config/mapo.json` usa el backend público de MAPO.

El bucket `user-media` de MAPO es privado. El backend reenvía el token del usuario en las lecturas de fotos para aplicar las políticas de Storage. El dueño puede acceder a sus fotos y las cuentas autenticadas pueden ver imágenes asociadas a planes publicados. Para habilitarlo al desplegar el backend de MAPO, configura `SUPABASE_PRIVATE_MEDIA=true`.

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
recuperación de contraseña. Android e iOS declaran `mapo://auth-callback`;
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

F5 y las compilaciones usan `config/mapo.json`, que solo contiene `API_BASE_URL`. Los secretos nunca deben agregarse a ese archivo.

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
una inscripción autenticada con fecha y número de personas. El servidor valida
requisitos, precio y cupos y la confirma automáticamente. El pago se realiza
presencialmente con el anfitrión; MAPO no cobra ni verifica ese pago externo.

## Alfa Android y operación del backend

```sh
cd backend
npm ci
npm test
npm start
```

Node 24 es el runtime del despliegue. `backend/.env.example` documenta las variables; `.env.local` está excluido de Git. En Vercel se configuran como variables privadas del proyecto MAPO, no se sube el archivo local. Backend: `https://mapo-experiencias-api.vercel.app`.

Completar `SMTP_PASSWORD` con la contraseña de aplicación del Gmail MAPO. Para aplicar además SMTP a Supabase Auth, las plantillas y los redirect URLs, ejecutar desde `backend`:

```sh
npm run configure:auth
```

El comando lee `SMTP_PASSWORD` y `SUPABASE_MANAGEMENT_TOKEN` desde `.env.local`, o los pide con entrada oculta. El token de administración es solo para esa configuración inicial: no va en Flutter ni es necesario para las peticiones normales del backend. Esta configuración queda pendiente hasta ingresar las credenciales y comprobar entrega real de un correo.

Desde Perfil, un turista puede solicitar ser anfitrión. Solo un administrador con rol asignado desde un entorno de confianza puede aprobar/rechazar/suspender. Elegir Anfitrión durante el registro crea un borrador, sin conceder permisos. Al aprobar se crea el perfil público y se habilita el editor de experiencias (borrador/publicada/pausa/archivo). En esta alfa las fotos se ingresan por URL HTTPS.

Las solicitudes validan precio, fecha, edades y cupos en Postgres, con bloqueo transaccional contra sobreventa. Las inscripciones se confirman automáticamente; el anfitrión puede cancelar y completar al llegar la fecha; el turista puede cancelar y reseñar una inscripción completada. La app muestra notificaciones dentro de la cuenta. Push, cobros y publicación en tiendas no forman parte de esta alfa.

Para asignar el primer administrador, registrar y confirmar la cuenta de la app de MAPO y ejecutar en SQL de confianza:

```sql
insert into public.user_roles(user_id, role)
select id, 'admin' from auth.users
where lower(email) = 'somosmapoapp@gmail.com' and email_confirmed_at is not null
on conflict (user_id, role) do nothing;
```

Esto no crea una cuenta ni una contraseña. Ser dueño del proyecto Supabase no crea automáticamente un usuario dentro de la app.

```sh
flutter test
flutter analyze
flutter build apk --release --dart-define-from-file=config/mapo.json
```

Salida: `build/app/outputs/flutter-apk/app-release.apk`. Se mantiene firma de debug para distribución privada de prueba; configurar una llave release propia antes de publicar o establecer una cadena de actualizaciones definitiva. En esta máquina Flutter usa Java 21 en `.toolchain/` para compatibilidad con Gradle.

Las pruebas de permisos y cupos contra la base están en `supabase/tests/host_workflow.sql`; usan una transacción que revierte sus datos de prueba. Las pruebas del backend están en `backend/test/`.

## Identidad visual

El símbolo de MAPO se usa en los iconos Android/iOS/web, el arranque y los espacios compactos. El logo con nombre se usa en acceso, cabecera del feed, correos y páginas públicas. Los archivos están en `assets/branding/`; el widget compartido es `MapoLogo`. Las variantes PNG se prepararon con ImageGen a partir del diseño aprobado, conservando el símbolo y separando el nombre según el uso.

`scripts/export-branding.ps1` exporta las densidades de iconos desde el símbolo. Después de compilar Android, la copia para compartir se guarda como `build/app/outputs/flutter-apk/MAPO_Android_arm64.apk`. La APK usa `mapo://auth-callback` y usa el identificador de aplicación `com.mapo.app`. Android instala esta versión como una aplicación nueva si la compilación anterior tenía otro identificador. Inicia sesión de nuevo para recuperar los datos de tu cuenta en Supabase.
