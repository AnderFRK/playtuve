# PlayTuve - Aplicación Móvil (Cliente Flutter)

Este repositorio contiene el código fuente de la aplicación móvil de **PlayTuve**, un cliente híbrido desarrollado en **Flutter** que permite a los usuarios buscar, reproducir y descargar pistas de audio directamente a sus dispositivos móviles, conectándose de forma dinámica a su propio nodo de servidor doméstico.

---

## Características Clave

* **Configuración Dinámica de Backend:** Pantalla dedicada para enlazar la aplicación a cualquier tipo de hosting del servidor (IP Local de la red WiFi, túneles seguros de Ngrok o conexiones SSH anónimas).
* **Validación de Conectividad:** Sistema integrado de prueba de conexión ("Probar conexión") con manejo avanzado de excepciones de red (`ClientException`, redirecciones y timeouts).
* **Descarga Directa de Flujos de Audio:** Recepción eficiente de archivos optimizados en formato de alta calidad (`.m4a` / AAC a 192kbps).
* **Gestión de Almacenamiento Local:** Integración nativa con el sistema de archivos del dispositivo para guardar y organizar la música descargada de manera persistente.
* **UI/UX Moderna:** Interfaz fluida basada en un esquema de diseño oscuro con acentos en rojo PlayTuve, optimizada para ofrecer una navegación intuitiva y reactiva.

---

## Requisitos Previos

Antes de compilar o ejecutar la aplicación, asegúrate de contar con el entorno de desarrollo correctamente configurado:

* **Flutter SDK:** Versión estable (compatible con Dart 3.x).
* **Android Studio / VS Code:** Con las extensiones de Flutter y Dart instaladas.
* **Dispositivo de Pruebas:** Un emulador configurado o un dispositivo físico Android/iOS con la *Depuración USB* activada.

---

## Instalación y Configuración

1. **Clonar el repositorio móvil:**
   ```bash
   git clone [https://github.com/tu-usuario/playtuve_mobile.git](https://github.com/tu-usuario/playtuve_mobile.git)
   cd playtuve_mobile