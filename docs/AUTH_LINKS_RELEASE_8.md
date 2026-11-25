# MAMBA 1.0.0+8: enlaces de correo

## Corrección

Las peticiones signup, recover, resend y cambio de email del gateway apuntan
a una página HTTPS fija de MAMBA, incluso desde APK anteriores que solicitan
un redirect mamba://. La página mantiene un botón explícito para abrir la app;
no intenta navegar automáticamente a un esquema que un navegador de correo
puede dejar en blanco. El destino de la app es fijo y solo se transfieren los
campos de autenticación permitidos. No se guardan tokens en almacenamiento web.

La página distingue registro, recuperación, cambio de correo, acceso genérico,
enlace vacío y error/vencimiento. No presenta una confirmación exitosa cuando
recibe un error ni renderiza la descripción externa como HTML. Se limpia la
barra de direcciones y se conserva no-store / no-referrer.

Flutter delega los enlaces a app_links/Supabase para evitar la navegación doble
del router. Los errores del stream de Auth muestran ayuda en lugar de quedar
sin manejar. La recuperación permanece activa durante una renovación de token.
Inicio de sesión incluye Reenviar confirmación de correo y valida el email
antes de solicitar el reenvío. La recuperación conserva su formulario en la APK.

## Configuración publicada

- Supabase MAMBA: pnprwhbpfgucdvjdygbt. Se verificaron site_url, allowlist
  exacta de los tres flows y las seis plantillas. SMTP y confirmación obligatoria
  se conservan. auth-links.cjs modifica solo URLs y plantillas, no credenciales.
- Vercel MAMBA: mamba-backend, despliegue READY de producción
  dpl_3JxDkdPk4xDHdFs68sgU8PG7G46f. Dominio mamba-backend.vercel.app.
- APK: build/app/outputs/flutter-apk/mamba.apk, paquete
  com.mamba.mamba_app, versionName 1.0.0, versionCode 8.
- SHA-256: 9CF06875085319B9F62CB8221DC887B897F0A41C07715D846B8762351907FC4F.

## Verificación

- Backend: 14 pruebas aprobadas. Incluyen PKCE, implicit, enlaces vencidos,
  parámetros de redirección hostiles, recuperación y conservación del intercambio.
- Flutter: 21 pruebas aprobadas; revisión estática sin incidencias. La suite de
  formulario y enlaces volvió a pasar tras incorporar el botón de reenvío.
- Supabase real: GET verify con OTP deliberadamente inválido para signup,
  recovery y email_change devuelve 303 hacia el HTTPS esperado y error; la
  página responde 200 HTML. No envía correos ni modifica cuentas.
- Navegador: páginas publicadas de registro, recuperación y vencimiento visibles,
  con botones correctos; sin navegación automática y sin pantalla en blanco.
- APK compilada; el manifest empaquetado confirma el manejador Flutter desactivado.
- Sin teléfono conectado. Falta comprobar un enlace válido desde el correo al
  dispositivo, tanto con app cerrada como abierta. No se declara esa prueba física
  como realizada ni se ha cambiado la contraseña de una cuenta real.

## Prueba en el celular

1. Instalar mamba.apk actualizada conservando los datos de la app.
2. Si el correo es antiguo, usar Reenviar confirmación de correo; los mensajes
   entregados antes del cambio conservan su destino original y no se reescriben.
3. Abrir el último correo en ese mismo celular; confirmar y tocar Abrir MAMBA.
4. Para recuperación, solicitarla desde ese celular y usar el correo más reciente;
   tocar Cambiar contraseña en MAMBA y guardar una nueva contraseña personalmente.
5. Verificar acceso, enlace ya usado, enlace vencido y apertura desde otro dispositivo.
   Si el correo ya está confirmado, se puede iniciar sesión normalmente.

La documentación técnica v1.0 describe el corte +7; esta nota registra las reglas
de autenticación que la sustituyen en +8. No cambian roles, reservas ni pagos.
