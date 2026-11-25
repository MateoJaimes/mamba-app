# MAMBA 1.0.0+5

Se corrigió la zona táctil del avatar: el botón de cámara se dibujaba fuera
de los límites del Stack y no recibía toques. La nueva cabecera compartida
mantiene portada, avatar y controles dentro de sus límites. Hay pruebas de
toque a través de las pantallas completas de turista y anfitrión.

Configuración muestra únicamente opciones. Se eliminaron foto, nombre,
correo, rol y botón de edición de la cabecera. Las fotos se cambian desde
el perfil; el anfitrión actualiza su perfil público mediante el flujo de
permisos existente, en lugar de cambiar una foto personal que no se muestra allí.

El perfil del anfitrión ahora muestra portada, avatar, nombre, usuario,
ubicación, biografía y momentos, con edición y configuración. La creación,
el listado y la edición de planes se concentran en Mis planes. El perfil
ya no repite la agenda, los formularios ni la lista administrativa de planes.

Mis planes usa tarjetas con foto, estado, precio y una acción principal de
edición. Publicar, pausar, archivar y ver publicación quedan en el menú de cada
plan. El editor tiene secciones, selección compacta de categorías, fotos
en miniatura con eliminación y botón de guardado fijo. El punto de encuentro
se elige en un mapa bajo demanda, sin introducir coordenadas manualmente.

El feed muestra los resultados antes de iniciar la precarga, utiliza una
lista continua para su carga inicial y elimina sus filtros de desenfoque.
Las fotos del carrusel usan un proveedor de imágenes cacheado y pintado
directo, sin la transición del contenedor anterior. No hay promesa de
rendimiento del 100 % en dispositivos sin medir.

Validación: 16 pruebas Flutter, incluyendo carga inicial tardía sin scroll,
comprobación de píxeles de una imagen cargada sin interacción, toque de cámara,
configuración sin cabecera personal, permisos de navegación y gestión de
planes. Se revisaron capturas de perfil, tarjetas y editor a 390 × 900.
No había un Android conectado; el selector nativo y el rendimiento en GPU
real siguen requiriendo prueba en el teléfono. Backend y esquema no cambian.

APK: build/app/outputs/flutter-apk/mamba.apk, versión 1.0.0+5.
