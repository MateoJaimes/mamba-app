# MAMBA 1.0.0+4 — espacio del anfitrión

Las cuentas con rol de anfitrión y perfil aprobado usan estas vistas:

- Primera pestaña: Mis planes, en lugar del mapa.
- Agenda: calendario de solicitudes de sus propias experiencias, por mes,
  fecha y plan. Marca días con solicitudes pendientes o aceptadas y muestra
  participantes. Las reservas que hizo como turista quedan fuera de esta vista.
- Perfil: espacio de anfitrión, con acceso a edición del perfil público,
  creación de planes, solicitudes, participantes y configuración.

Mis planes ofrece edición explícita, filtros por estado, publicación, pausa,
archivo y vista de la publicación. Archivar conserva el plan y las inscripciones;
no elimina historial. El editor permite cambiar fotos, precio, descripción,
categorías, ubicación, cupos y condiciones existentes.

En su propio perfil público, el anfitrión ve Administrar mis planes en lugar
de contactarse o seguirse a sí mismo. Los visitantes mantienen la vista pública.

La agenda muestra las fechas solicitadas por los turistas; no inventa salidas,
horarios ni disponibilidad. No se ha añadido un sistema de turnos o franjas
horarias. Desde una solicitud se abre la gestión del plan y fecha concretos.

La navegación se decide con roles y aprobación del servidor, nunca con la
preferencia escogida al registrarse. Los cambios se envían al flujo existente
del backend, que valida propiedad y permisos. No hay cambios de esquema ni
requiere un nuevo despliegue del backend.

Verificación: 11 pruebas Flutter, análisis sin problemas y prueba SQL bajo el
rol autenticado del anfitrión para publicar, pausar y archivar, con rollback.
APK: build/app/outputs/flutter-apk/mamba.apk, versión 1.0.0+4.

Prueba en Android: iniciar sesión en la cuenta MAMBA, abrir Mis planes,
editar uno, pausarlo y publicarlo de nuevo. Revisar Perfil y Agenda. Desde
una cuenta turista, solicitar una fecha; en la cuenta anfitriona comprobar
el marcador del calendario, número de participantes y gestión de esa solicitud.
