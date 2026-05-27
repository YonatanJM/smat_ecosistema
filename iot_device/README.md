# Mi Dispositivo IoT (Script de Telemetría)
Este es el script de Python (`sensor_emitter.py`) que creé para simular el sensor de agua del río. Lo que hace es generar números de forma automática para enviarlos a nuestra base de datos en el backend sin que tengamos que meter los datos a mano.

## ¿Cómo se conecta de forma segura con la nube usando Token JWT?
Para que nadie pueda meter datos falsos a nuestro servidor ni hackear las estaciones, el script sigue estos pasos sencillos para identificarse con seguridad:

1. **Pedir permiso:** Cuando prendemos el script de Python, este primero va hacia la ruta de inicio de sesión de nuestra API (`POST /auth/token`) y le manda el usuario y la contraseña fijos que le dimos a este sensor.
2. **Guardar la "llave" (Token):** Si los datos son correctos, el backend nos devuelve un texto largo y seguro que se llama **Token JWT**. Es como una llave digital con pase temporal.
3. **Mandar los datos con la llave:** Cada vez que el sensor mide el agua y quiere mandar el número con un `POST /lecturas/`, mete ese Token JWT en los encabezados de la petición (en la parte de `Authorization: Bearer`).
4. **Validación:** El servidor de FastAPI recibe el número, revisa que la llave digital sea válida y, si todo está bien, recién guarda la lectura en la base de datos SQLite.