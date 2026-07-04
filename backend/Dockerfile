# 1. Imagen base ligera de Python
FROM python:3.11-slim

# 2. Instalar curl para el Healthcheck (Control de salud de la guía)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 3. Definir el directorio de trabajo base
WORKDIR /app

# 4. Copiar e instalar las librerías
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. COPIAR LA CARPETA APP CON SU NOMBRE ORIGINAL
# Esto creará la ruta /app/app/ dentro de Docker, haciendo válidas las rutas relativas
COPY app/ ./app/

# 6. Crear la carpeta para la base de datos SQLite
RUN mkdir -p /app/data

# 7. Ejecutar Uvicorn llamando al módulo del paquete
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]