# Comprobación en un Android real

Instalar `build/app/outputs/flutter-apk/mamba.apk` (versión 1.0.0+3).

1. Entrar como turista. En Perfil, abrir el engranaje, elegir país y ciudad.
   Para Colombia, seleccionar departamento y municipio. Cambiar a USD y comprobar
   el precio en inicio, detalle, mapa, anfitrión e inscripciones. Volver a COP.
2. Subir avatar, portada y un momento desde el selector de fotos del teléfono.
   Cancelar el selector una vez: la pantalla debe seguir operativa. Mantener
   pulsado el momento y quitarlo. Los documentos privados nunca van a esta galería.
3. Abrir un plan con dos fotos y deslizar horizontalmente sin abrir el perfil
   del anfitrión. Deslizar después el contenido verticalmente.
4. Recorrer el feed varias veces con Wi-Fi y con datos móviles. Las imágenes
   próximas se anticipan y se reutilizan; medir tirones con un perfil de rendimiento
   si persisten. La precarga no elimina la latencia de una conexión lenta.
5. Rotar y desplazar el mapa. Usar Orientar al norte y Centrar planes.
   Comprobar nombre, ausencia de reseñas cuando corresponde y precio del marcador.
6. Entrar como somosmambaapp@gmail.com. Configuración → Mi espacio de anfitrión.
   Editar uno de los tres planes, escoger varias categorías y añadir una foto
   propia. Guardar y comprobar su aparición bajo cada categoría.
7. Enviar una solicitud de inscripción desde una segunda cuenta turista,
   comprobar que el anfitrión puede aceptarla y que el turista ve el cambio.
   Cancelar la solicitud al terminar la prueba.

Las pruebas automáticas no sustituyen estas comprobaciones de galería,
conexión móvil, gestos físicos y fluidez del dispositivo.
