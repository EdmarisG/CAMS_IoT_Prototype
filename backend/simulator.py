import requests
import time
import random
import math

SERVER_URL = "http://localhost:5000/api/sensor"

def send_data(pressure, alert_level):
    try:
        payload = {'presion': pressure, 'alerta': alert_level}
        response = requests.post(SERVER_URL, json=payload, timeout=5)
        return response.status_code == 200
    except:
        return False

def calculate_alert(pressure):
    if pressure < 5.0:
        return 'FUGA'
    elif pressure > 35.0:
        return 'OBSTRUCCIÓN'
    return 'NORMAL'

print("Simulador ESP32 - CAMS IoT")
print("Presione Ctrl+C para detener\n")
choice = input("Elegir escenario (1-NORMAL, 2-LEAK, 3-OBSTRUCTION): ").strip()
scenarios = {'1': ('NORMAL', 20, 1.5), '2': ('LEAK', 3, 0.5), '3': ('OBSTRUCTION', 42, 2)}
scenario_name, base_pressure, variance = scenarios.get(choice, scenarios['1'])
print(f"\nSimulando: {scenario_name}\nEnviando datos...\n")
iteration = 0
start_time = time.time()
try:
    while True:
        iteration += 1
        pressure = base_pressure + random.uniform(-variance, variance)
        pressure = max(-5, min(50, pressure))
        alert_level = calculate_alert(pressure)
        success = send_data(pressure, alert_level)
        status = "OK" if success else "FAIL"
        print(f"[{iteration}] {status} {alert_level:12s} | Presion: {pressure:6.2f} cmH2O")
        time.sleep(1)
except KeyboardInterrupt:
    print("\n\nSimulacion detenida")
