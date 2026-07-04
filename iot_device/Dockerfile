# 1. Imagen base ligera
FROM python:3.11-slim

# 2. Directorio de trabajo
WORKDIR /app

# 3. Instalar las librerias directamente ya que son pocas
RUN pip install --no-cache-dir paho-mqtt requests

# 4. Copiar el script del puente al contenedor
COPY mqtt_bridge.py .

# 5. Ejecutar el daemon
CMD ["python", "mqtt_bridge.py"]