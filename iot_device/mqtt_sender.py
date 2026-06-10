import paho.mqtt.client as mqtt
import json
import time
import random

# Configuración del Broker público para pruebas
BROKER = "broker.hivemq.com" 
PORT = 1883
TOPIC = "fisi/smat/estaciones/1"  # Publicamos como la estación ID 1

client = mqtt.Client()
client.connect(BROKER, PORT)

print("Sensor Emulado SMAT iniciado. Publicando datos...")

try:
    while True:
        # Estructura del payload con los datos del sensor
        payload = {
            "valor": round(random.uniform(20.0, 60.0), 2),
            "timestamp": time.time()
        }
        
        # Publicar datos en el "Topic" en formato JSON string
        client.publish(TOPIC, json.dumps(payload))
        print(f"Enviado por MQTT: {payload}")
        
        # Esperar 10 segundos antes de la siguiente lectura
        time.sleep(10)
except KeyboardInterrupt:
    print("\nPublicación detenida por el usuario.")
    client.disconnect()