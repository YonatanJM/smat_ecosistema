import paho.mqtt.client as mqtt
import requests
import json
import sys
import time
import os
from datetime import datetime

# CONFIGURACIÓN DEL ENTORNO SMAT

# CONFIGURACIÓN DEL ENTORNO SMAT

MQTT_BROKER = "broker.hivemq.com" 
MQTT_PORT = 1883                  
MQTT_TOPIC = "fisi/smat/estaciones/+/lecturas" 
API_URL = os.environ.get("API_URL", "http://backend:8000/lecturas/") 

JWT_TOKEN = os.environ.get("JWT_TOKEN", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzgzMTk1ODMzfQ.IkHl86m2AhDbVq8WsOuAKJCFkdfWFf5A-b8v-72xW_s")

# 1. MEMORIA CACHÉ LOCAL (RETO 1 - SEMANA 11)

last_saved_value = {}  
last_saved_time = {}  

def on_connect(client, userdata, flags, rc):
    if rc == 0: 
        print(" Conectado exitosamente al Broker MQTT") 
        client.subscribe(MQTT_TOPIC) 
        print(f" Escuchando transmisiones en el tópico: {MQTT_TOPIC}") 
    else:
        print(f" Error de conexión al Broker. Código de retorno: {rc}") 
        sys.exit(1) 

def on_message(client, userdata, msg):
    try:
        # 1. Decodificar el payload binario de MQTT a JSON string 
        payload_raw = msg.payload.decode("utf-8") 
        data_json = json.loads(payload_raw) 
        
        # 2. Extraer el ID dinámico de la estación desde la estructura del tópico 
        topic_parts = msg.topic.split('/')
        estacion_id = int(topic_parts[3])  
        
        print(f"\n📡 Telemetria recibida de Estación [{estacion_id}]: {data_json}") 
        
        nuevo_valor = float(data_json["valor"]) 
        current_time = time.time()
        
        # 2. LÓGICA DEL FILTRO DE OPTIMIZACIÓN (RETO 2 - SEMANA 11) 
        debe_enviar = False
        motivo_ingesta = ""
        
        # Condición A: Si es el primer dato histórico de esa estación en la caché 
        if estacion_id not in last_saved_value:
            debe_enviar = True
            motivo_ingesta = "Primer dato de la estación (Inicialización de caché)"
        else:
            valor_anterior = last_saved_value[estacion_id]
            tiempo_anterior = last_saved_time[estacion_id]
            
            # Calcular la variación porcentual absoluta 
            variacion = abs(nuevo_valor - valor_anterior) / valor_anterior
            tiempo_transcurrido = current_time - tiempo_anterior
            
            # Condición B: Variación mayor al ± 5% respecto al último guardado 
            if variacion > 0.05:
                debe_enviar = True
                motivo_ingesta = f"Variación significativa detectada: {variacion * 100:.2f}% (Superior al 5%)"
            
            # Condición C: Reporte mínimo de vida (Heartbeat > 60 segundos) 
            elif tiempo_transcurrido > 60:
                debe_enviar = True
                motivo_ingesta = f"Filtro Heartbeat activo: Transcurrieron {tiempo_transcurrido:.1f}s sin variaciones"

        # PROCESAR INGESTA O BLOQUEO SE SEGÚN FILTRO
        if debe_enviar:
            # 3. Formatear la carga útil incluyendo el campo "fecha" requerido por tu FastAPI
            api_payload = {
                "valor": float(nuevo_valor), 
                "estacion_id": int(estacion_id),
                "fecha": datetime.utcnow().isoformat() + "Z"  
            }
            
            # 4. Ingestión de datos segura mediante HTTP POST con Header Bearer Token 
            headers = {
                "Content-Type": "application/json", #
                "Authorization": f"Bearer {JWT_TOKEN}" 
            }
            
            response = requests.post(API_URL, json=api_payload, headers=headers) 
            
            if response.status_code == 200 or response.status_code == 201: 
                print(f"   └── [DB Sincronizada] {motivo_ingesta}. Lectura de {api_payload['valor']} cm guardada en SQLite.")
                
                # ACTUALIZAR CACHÉ ÚNICAMENTE SI LA INGESTA FUE EXITOSA
                last_saved_value[estacion_id] = nuevo_valor 
                last_saved_time[estacion_id] = current_time  
            else:
                print(f"   └── [Fallo de Ingesta] API rechazó el dato. Código: {response.status_code} - {response.text}") 
        else:
            # Validación por Consola de la Omitación (Requisito 3 del reto) 
            print(f"   └── 🛑 [FILTRADO OMITIDO] Variación menor al 5% y tiempo menor a 60s. Petición HTTP bloqueada.") 

    except KeyError as e:
        print(f" ❌ Error de esquema: Falta la llave {e} en el payload MQTT.") 
    except ValueError:
        print(" ❌ Error de casteo: El valor o el ID de la estación no son numéricos.") 
    except Exception as e:
        print(f" ❌ Error critico en el Bridge: {e}") 

bridge_client = mqtt.Client() 
bridge_client.on_connect = on_connect 
bridge_client.on_message = on_message 

try:
    print(" Inicializando el Bridge de Acoplamiento SMAT...") 
    bridge_client.connect(MQTT_BROKER, MQTT_PORT, 60) 
    bridge_client.loop_forever() 
except KeyboardInterrupt:
    print("\n Bridge detenido por el administrador.") 