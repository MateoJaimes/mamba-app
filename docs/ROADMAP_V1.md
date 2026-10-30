# Hoja de ruta de MAMBA 1.0

**Actualizada:** 26 de octubre de 2026  
**Objetivo:** lanzar una app móvil para descubrir experiencias, reservarlas y gestionar las reservas.  
**Estado general:** prototipo visual y estructura inicial; todavía no está lista para producción.

## Cómo vamos a usar este documento

- `✅ Hecho`: implementado y comprobado en el flujo correspondiente.
- `🟡 En curso`: existe una parte, falta completar o validar.
- `⬜ Pendiente`: aún no implementado.
- Cada funcionalidad pasa a **Hecho** solo cuando cumple su criterio de cierre y está verificada en un dispositivo o entorno de ejecución.
- Trabajaremos por cortes verticales pequeños: interfaz, datos, errores y verificación de una funcionalidad antes de saltar a la siguiente.
- Actualizar este archivo al cerrar cada tarea: estado, decisión pendiente y siguiente paso.

## Resumen de estado

| Funcionalidad | Estado | Qué hay hoy | Qué falta para cerrarla |
|---|---|---|---|
| Base de app y navegación | 🟡 En curso | Flutter, tema oscuro esmeralda, GoRouter y barra flotante | Corregir prueba de plantilla, validar compilación y documentar comandos/configuración |
| Feed y descubrimiento | 🟡 En curso | Feed visual con publicaciones y datos de demostración | Cargar API real, estados de error/vacío, paginación real y abrir detalle |
| Cuentas y sesiones | ⬜ Pendiente | Tablas de usuarios en SQL; servicios de app vacíos | Decidir proveedor de identidad e implementar registro, login, recuperación y sesión |
| Detalle de experiencia | ⬜ Pendiente | Entidades y DTO parcial | Pantalla con contenido, proveedor, fotos, precio, disponibilidad y reglas reales |
| Mapa y búsqueda | ⬜ Pendiente | Dependencias de mapa/ubicación; pantalla de mapa de marcador | Mapa funcional, permisos, búsqueda y filtros o excluirlo expresamente del MVP |
| Reservas y calendario | 🟡 En curso | Tablas SQL; calendario de app solo muestra estado vacío | Selección de disponibilidad, checkout, confirmación, cancelación y lista de reservas |
| Pagos | ⬜ Pendiente | Tablas SQL de pagos y reembolsos | Elegir proveedor, integrar flujo seguro, webhooks y estados idempotentes |
| Favoritos y acciones sociales | 🟡 En curso | Botones locales en publicaciones; tablas SQL de favoritos | Persistir, sincronizar y definir si comentarios/me gusta son parte de 1.0 |
| Perfil y soporte | 🟡 En curso | Pantalla estática y menú visual | Datos del usuario, edición, ajustes, ayuda y cerrar/eliminar cuenta |
| Notificaciones | ⬜ Pendiente | Dependencia y tablas SQL | Permisos, registro de dispositivo, envío y preferencias |
| Seguridad y backend | ⬜ Pendiente | Scripts SQL amplios en esquema `mamba` | Elegir arquitectura de auth, acceso de datos, RLS/GRANT, vistas seguras y despliegue verificable |
| Preparación de tiendas | ⬜ Pendiente | Carpetas Android e iOS generadas | IDs/nombres finales, firma release, iconos, privacidad, builds y checklist de publicación |

## Ruta por funcionalidades

### 0. Cimientos y alcance de V1

**Estado: 🟡 En curso**

- [x] Existe app Flutter con separación inicial `core`, `features` y `shared`.
- [x] La app inicia con GoRouter y usa navegación inferior persistente.
- [x] Se creó tema oscuro gris/verde y estilo visual redondeado.
- [ ] Definir plataformas de lanzamiento: Android, iOS o ambas. No incluir Web en V1 salvo decisión explícita.
- [ ] Cerrar alcance comercial de V1: quién publica experiencias, quién confirma reservas y quién atiende cancelaciones.
- [ ] Acordar entornos de desarrollo, staging y producción y cómo se inyectan sus variables.
- [ ] Reparar `test/widget_test.dart`, que aún valida el contador de la app plantilla.
- [ ] Añadir CI con formato, análisis, pruebas y compilación de release.

**Criterio de cierre:** cualquier persona del equipo puede configurar el proyecto siguiendo el README y generar una compilación de prueba reproducible.

### 1. Cuentas, acceso y perfil

**Estado: ⬜ Pendiente**

- [ ] Elegir una sola fuente de identidad. El SQL define `mamba.users`; la app no integra todavía Supabase Auth ni otra solución.
- [ ] Diseñar y construir registro, inicio/cierre de sesión y recuperación de contraseña.
- [ ] Persistir sesión de forma segura y proteger rutas privadas.
- [ ] Crear/editar nombre, foto, teléfono y preferencias del perfil.
- [ ] Definir baja de cuenta y tratamiento de datos asociados.

**Criterio de cierre:** una persona puede crear su cuenta, recuperar acceso, conservar la sesión y administrar su perfil sin exponer datos de otra cuenta.

### 2. Feed, búsqueda y ficha de experiencia

**Estado: 🟡 En curso**

- [x] Feed visual con tarjetas separadas, fotos, nombre del oferente y datos principales.
- [x] Interfaz de me gusta, comentarios, compartir y guardar publicación.
- [ ] Cambiar datos de demostración por experiencias publicadas desde backend.
- [ ] Acordar el contrato de API y corregir la diferencia entre `ExperienceDto` y `vw_public_experiences`.
- [ ] Implementar paginación, actualización, carga, error y feed vacío usando respuestas reales.
- [ ] Crear ficha de detalle con proveedor, galería, descripción, ubicación, duración, precio, inclusiones, requisitos y políticas.
- [ ] Agregar búsqueda y filtros del MVP (por ejemplo ciudad, categoría, fecha y precio).
- [ ] Confirmar licencia y disponibilidad de fotos; reemplazar URLs de Unsplash por imágenes autorizadas para producción.

**Criterio de cierre:** la app lista experiencias publicadas y permite abrir una ficha completa; las fallas de red se recuperan con mensajes y reintento.

### 3. Ubicación y mapa

**Estado: ⬜ Pendiente**

- [ ] Decidir si el mapa es requisito de la primera versión.
- [ ] Si entra: solicitar permiso solo al usar la función, mostrar mapa real y marcadores desde backend.
- [ ] Resolver denegación de permiso, ubicación desactivada y alternativa de búsqueda manual.
- [ ] Revisar proveedor, límites, atribución y costos de mapas/geocodificación.

**Criterio de cierre:** mapa y búsqueda siguen funcionando sin permiso de ubicación y presentan resultados válidos para la ciudad elegida.

### 4. Disponibilidad, reserva y calendario

**Estado: 🟡 En curso**

- [x] Existe un esquema SQL inicial para horarios, disponibilidad y reservas.
- [ ] Mostrar fechas y cupos disponibles de una experiencia real.
- [ ] Validar disponibilidad en servidor al confirmar para evitar sobreventa.
- [ ] Capturar participantes y datos obligatorios; validar restricciones del oferente.
- [ ] Mostrar resumen de precio, impuestos, moneda, descuentos y políticas antes del pago.
- [ ] Crear reserva pendiente y manejar expiración/abandono del checkout.
- [ ] Mostrar reservas futuras e historial en el calendario/perfil.
- [ ] Permitir cancelar y mostrar claramente estado y reembolso aplicable.

**Criterio de cierre:** una reserva no se confirma por el cliente; queda confirmada por estado validado del servidor y aparece en el historial de ambas partes.

### 5. Pago y reembolso

**Estado: ⬜ Pendiente**

- [ ] Definir país, moneda inicial, medios de pago y proveedor compatible con el modelo comercial.
- [ ] Crear el pago desde un backend seguro; nunca confiar el total final al cliente móvil.
- [ ] Verificar webhooks, firma, idempotencia, pagos duplicados y estados pendientes/fallidos.
- [ ] Implementar reembolso total/parcial y conciliación operativa.
- [ ] Probar sandbox con casos de éxito, rechazo, demora, repetición y cancelación.

**Criterio de cierre:** solo un evento verificado del proveedor puede cambiar el estado final del pago/reserva y existe una forma de conciliar operaciones.

### 6. Favoritos, comentarios y valoraciones

**Estado: 🟡 En curso**

- [x] Controles visuales de guardar, me gusta y comentarios en publicaciones.
- [ ] Guardar/quitar favoritos en backend por usuario y sincronizarlos entre sesiones.
- [ ] Definir el modelo de publicaciones: las tablas actuales cubren favoritos y reseñas, pero no una conversación de comentarios del feed ni likes de publicaciones.
- [ ] Implementar comentarios, reportes y moderación solo si forman parte del MVP.
- [ ] Permitir reseñar únicamente reservas completadas, con controles contra duplicados y abuso.

**Criterio de cierre:** acciones persistentes, asociadas a la persona correcta y con reglas contra spam/abuso; si lo social queda fuera de V1, ocultar acciones que aparenten persistir.

### 7. Notificaciones y comunicación

**Estado: ⬜ Pendiente**

- [ ] Definir mensajes transaccionales de V1: reserva creada/confirmada, cambio, cancelación y reembolso.
- [ ] Integrar push y canal alternativo esencial (correo, por definir).
- [ ] Solicitar permisos en contexto y permitir preferencias/desactivación.
- [ ] Decidir si el chat oferente-cliente del esquema SQL queda fuera de V1.

**Criterio de cierre:** los mensajes reflejan estados reales del servidor, no duplican eventos y respetan preferencias.

### 8. Seguridad, operación y publicación

**Estado: ⬜ Pendiente**

- [ ] Convertir los scripts SQL en migraciones ordenadas, repetibles y revisables; resolver duplicados `ss.sql`/`vvv.sql` y aclarar el respaldo binario con extensión `.sql`.
- [ ] Confirmar qué esquema se expone por Data API. Revisar RLS, `GRANT`, funciones y vistas antes de habilitar acceso desde cliente.
- [ ] Restringir las vistas administrativas/financieras y datos personales; evaluar `security_invoker` donde aplique.
- [ ] Configurar logs sin tokens ni datos sensibles, alertas, respaldos y procedimiento de restauración.
- [ ] Configurar ID de paquete, nombre MAMBA, iconos, firma y secretos de release para cada plataforma objetivo.
- [ ] Preparar política de privacidad, términos, soporte y reglas de reservas/reembolsos.
- [ ] Hacer una beta cerrada y corregir bloqueos antes de enviar a tiendas.

**Criterio de cierre:** revisión de seguridad aprobada, recuperación de respaldo practicada y builds firmados probados en dispositivos reales.

## Próximo corte recomendado

**Primer flujo vertical: feed real de experiencias.** Es el siguiente paso porque valida el contrato entre la app y la base antes de construir detalle, disponibilidad y reservas.

1. Elegir dónde vive el endpoint/cliente backend y qué esquema será accesible.
2. Definir el DTO del feed con proveedor, imágenes, ubicación y precio.
3. Implementar fuente remota + estados de carga/error/vacío + paginación.
4. Probar contra un entorno de desarrollo con datos no sensibles.
5. Marcar esta funcionalidad como **Hecho** solo al confirmar el recorrido en dispositivo.

## Decisiones que bloquean varios módulos

1. ¿Lanzamos Android, iOS o ambos en V1?
2. ¿La app será solo para clientes al inicio, con oferentes cargados/gestionados por el equipo, o también incluirá herramientas para oferentes?
3. ¿Qué sistema de identidad y backend será la fuente oficial: Supabase Auth/Postgres o backend propio con el esquema actual?
4. ¿Pagos en línea entran en el primer lanzamiento o se inicia con solicitud/reserva confirmada manualmente?

Hasta resolver estas decisiones podemos avanzar en el contrato de feed y la experiencia visual, pero no cerrar seguridad, pagos ni publicación.
