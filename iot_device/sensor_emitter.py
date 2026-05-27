import requests
import time
import random

# ==========================================
# CONFIGURACIÓN (Ajusta esto según tu API)
# ==========================================
API_URL = "http://localhost:8000/lecturas/"  # URL del endpoint de tu backend [cite: 34]
ESTACION_ID = 1  # ID de la estación registrada en tu base de datos [cite: 34]
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzc5OTAxNzczfQ.rHiElfhoo5b4RJRPNjfoOBKk5SJ-XZYnKlw4NDKijlU"  # Pega aquí el token obtenido en tu login [cite: 34]

def leer_sensor_emulado():
    """Simula la lectura del nivel del río entre 10.5 y 85.0 cm."""
    return round(random.uniform(10.5, 85.0), 2)  # [cite: 36]

def enviar_telemetria():
    print(f"--- Iniciando Emisor IoT para Estación {ESTACION_ID} ---")  # [cite: 38]
    
    # Configuramos la cabecera con el Token JWT para la autenticación [cite: 45, 46]
    headers = {
        "Authorization": f"Bearer {TOKEN}"
    }
    
    while True:  # [cite: 39]
        # 1. Obtener la lectura simulada [cite: 40]
        valor = leer_sensor_emulado()
        
        # 2. Lógica de Alerta de Desborde y Frecuencia Dinámica (Reto Semana 9)
        if valor > 70.0:  # [cite: 71, 73]
            print(f"[ALERTA] Umbral de inundación superado: {valor} cm")  # [cite: 71]
            tiempo_espera = 2  # Modo de Emergencia: envía cada 2 segundos [cite: 73]
        else:
            print(f"[INFO] Nivel estable: {valor} cm")
            tiempo_espera = 10  # Modo Normal: envía cada 10 segundos [cite: 72]
            
        # 3. Preparar los datos para el envío [cite: 41]
        payload = {
            "valor": valor,  # [cite: 43]
            "estacion_id": ESTACION_ID  # [cite: 44]
        }
        
        # 4. Intentar enviar los datos a la API de FastAPI [cite: 48, 49]
        try:
            response = requests.post(API_URL, json=payload, headers=headers)  # [cite: 49]
            
            # Verificamos si el servidor recibió el dato correctamente (200 o 201) [cite: 49]
            if response.status_code in [200, 201]:  # [cite: 49]
                print(f"[OK] Lectura enviada exitosamente: {valor} cm")  # [cite: 50]
            else:
                print(f"[ERROR] Código de estado del servidor: {response.status_code}")  # [cite: 52]
                print(f"Detalle: {response.text}")
                
        except Exception as e:
            print(f"[CRÍTICO] No hay conexión con el servidor: {e}")  # [cite: 53]
            
        # 5. Pausa dinámica según el estado del río (2s o 10s) [cite: 54, 72, 73]
        print(f"Esperando {tiempo_espera} segundos para la siguiente lectura...\n")
        time.sleep(tiempo_espera)  # [cite: 54]

if __name__ == "__main__":  # [cite: 55]
    enviar_telemetria()  # [cite: 56]