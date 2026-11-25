# MAMBA 1.0.0+3

Perfil del turista con portada y avatar del dispositivo, biografía, usuario,
ubicación, hasta ocho intereses y galería de hasta 24 momentos. Las imágenes
son públicas; las filas de la galería solo son administrables por su dueño.
Configuración contiene ubicación, divisa, inscripciones, guardados, reseñas,
notificaciones, anfitrión, soporte y cierre de sesión.

Los países y territorios se basan en GeoNames/Unicode (250 entradas). Colombia
tiene 32 departamentos, Bogotá D.C. y 1.122 entradas de DIVIPOLA. Fuera de
Colombia la ciudad se escribe manualmente. Fuentes:
- https://www.geonames.org/export/ (CC BY, atribución a GeoNames)
- https://www.datos.gov.co/resource/gdxc-w37w.json (DANE / DIVIPOLA)

14 divisas: COP, USD, EUR, GBP, MXN, BRL, CAD, AUD, JPY, CHF, CNY, PEN, CLP, ARS.
La preferencia se guarda por cuenta. ExchangeRate-API entrega tasas diarias;
las conversiones son aproximadas y muestran la fecha de la tasa. COP es la
moneda original de los planes y de las solicitudes; no hay pagos en la app.
Una tasa de respaldo solo se usa durante un máximo de siete días y se marca
como anterior. Fuente: https://www.exchangerate-api.com/docs/free

Los planes admiten de una a seis categorías. El feed filtra en el servidor,
anticipa la carga de las siguientes imágenes y usa imágenes decodificadas
con límite de ancho. El desenfoque de bordes pasa de diez filtros a dos.
El detalle deja pasar los gestos a través del degradado decorativo.
El mapa centra los planes visibles, permite volver al norte y muestra nombre,
calificación real (o ausencia de reseñas) y precio en cada marcador.

MAMBA Experiencias pertenece a la cuenta verificada somosmambaapp@gmail.com.
Se retiraron exclusivamente los anfitriones y planes de demostración, que
no tenían inscripciones. No se añadieron reseñas, documentos ni puntuaciones.

Planes publicados, editables por la cuenta anfitriona:
- Comuna 13: arte, memoria y sabores — COP 60.000 / persona, 3 horas.
- Café de origen: del aroma a la taza — COP 65.000 / persona, 2 horas.
- Santa Elena: bosque, senderos y aire de montaña — COP 55.000 / persona, 3 horas.

Son propuestas de MAMBA basadas en actividades y lugares reales; requieren
confirmación de disponibilidad por el anfitrión. No afirman alianzas con
operadores externos. Las descripciones identifican las fotos de referencia.
El precio cultural se contrastó con ofertas de COP 60.000 de Culture Colombia
Tours y SAG Tour. La cata se contrastó con la experiencia de COP 65.000 de
Cafés de Origen. El precio de Santa Elena es una propuesta editorial de MAMBA,
no una tarifa oficial de Parque Arví. Transporte y accesos privados excluidos.
Referencias:
- https://culturecolombiatours.com/es/tour-comuna-13-medellin
- https://www.sagtourmedellin.com/to_book/tour-comuna-13/
- https://www.cafesdeorigen.net/experiencias/

Validación: seis pruebas Flutter, ocho pruebas NestJS, comprobaciones SQL
con rollback para aislamiento de perfiles, ubicaciones dependientes y edición
de categorías como anfitrión autenticado. Backend publicado y consultado a
través de su URL de producción. Pendiente prueba física Android de fluidez,
selector de fotos y carga sobre conexión móvil; no se promete rendimiento
del 100 % sin mediciones en dispositivo.

Mockup: assets/design/tourist-profile-mockup.png.
APK: build/app/outputs/flutter-apk/mamba.apk.
