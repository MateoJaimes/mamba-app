# MAMBA 1.0.0+7 — inscripción automática y pago presencial

El turista elige fecha y participantes y toca Confirmar mi inscripción.
La base de datos valida sesión, plan publicado, edades, fecha y cupos y
confirma la inscripción en la misma transacción. El anfitrión recibe una
notificación y ve los participantes en su agenda; no acepta ni rechaza.
Se conservan la cancelación, la finalización y las reseñas posteriores.

El pago se realiza presencialmente y directamente con el anfitrión. No
se exige ni se intenta un cobro online. La app tampoco verifica ni registra
que ese pago externo haya ocurrido. No hay pasarela integrada.

Representación en la base:
- status=accepted significa Confirmada en la interfaz.
- payment_method=in_person describe el método acordado.
- payment_status=external_untracked evita fingir un pago verificado.
- Precio y total se calculan con el importe original del plan en COP.

Las solicitudes antiguas pendientes se convierten en confirmadas; al revisar
la base no había inscripciones existentes. Los estados históricos siguen
siendo compatibles. Las versiones anteriores de la APK ya usan el nuevo
comportamiento del servidor, pero deben actualizarse para ver los mensajes
correctos de confirmación y pago.

Se corrigió también el mensaje anterior que anunciaba una reserva local sin
confirmar después de guardarla en el servidor. La app exige sesión y respuesta
del servidor para confirmar. Si falla una lectura posterior al guardado, no
invita a repetir una inscripción que ya fue creada.

Migración aplicada en MAMBA:
supabase/migrations/20261123211304_automatic_booking_in_person_payment.sql.
Prueba con rollback: supabase/tests/automatic_booking.sql. Comprueba cupos,
confirmación, precio, notificaciones, bloqueo de aceptación manual, bloqueo de
finalización anticipada, permisos de pago y liberación de cupos al cancelar.

El sitio público se actualizó en el proyecto mamba-backend de la cuenta MAMBA.
APK: build/app/outputs/flutter-apk/mamba.apk, 1.0.0+7.

Aviso de seguridad preexistente y ajeno a esta migración: Supabase mantiene
desactivada la protección de contraseñas filtradas. No se detectaron nuevos
avisos de RLS por este cambio. Documentación de la mejora pendiente:
[Protección de contraseñas filtradas](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
