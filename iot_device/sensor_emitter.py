import requests
import time
import random

# CONFIGURACIÓN (Ajusta esto según tu API)
API_URL = "http://localhost:8000/lecturas/"  
ESTACION_ID = 1  
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzgzMTk1ODMzfQ.IkHl86m2AhDbVq8WsOuAKJCFkdfWFf5A-b8v-72xW_s" 
def leer_sensor_emulado():
    """Simula la lectura del nivel del río entre 10.5 y 85.0 cm."""
    return round(random.uniform(10.5, 85.0), 2)  

def enviar_telemetria():
    print(f"--- Iniciando Emisor IoT para Estación {ESTACION_ID} ---")  
    
    # Configuramos la cabecera con el Token JWT para la autenticación
    headers = {
        "Authorization": f"Bearer {TOKEN}"
    }
    
    while True:  
        # 1. Obtener la lectura simulada
        valor = leer_sensor_emulado()
        
        # 2. Lógica de Alerta de Desborde y Frecuencia Dinámica (Reto Semana 9)
        if valor > 70.0:  
            print(f"[ALERTA] Umbral de inundación superado: {valor} cm")
            tiempo_espera = 2  # Modo de Emergencia: envía cada 2 segundos 
        else:
            print(f"[INFO] Nivel estable: {valor} cm")
            tiempo_espera = 10  # Modo Normal: envía cada 10 segundos 
            
        # 3. Preparar los datos para el envío 
        payload = {
            "valor": valor, 
            "estacion_id": ESTACION_ID  
        }
        
        # 4. Intentar enviar los datos a la API de FastAPI 
        try:
            response = requests.post(API_URL, json=payload, headers=headers)  
            
            # Verificamos si el servidor recibió el dato correctamente (200 o 201) 
            if response.status_code in [200, 201]:  
                print(f"[OK] Lectura enviada exitosamente: {valor} cm")  
            else:
                print(f"[ERROR] Código de estado del servidor: {response.status_code}")  
                print(f"Detalle: {response.text}")
                
        except Exception as e:
            print(f"[CRÍTICO] No hay conexión con el servidor: {e}")  
            
        # 5. Pausa dinámica según el estado del río (2s o 10s) 
        print(f"Esperando {tiempo_espera} segundos para la siguiente lectura...\n")
        time.sleep(tiempo_espera)  

if __name__ == "__main__":  
    enviar_telemetria()  