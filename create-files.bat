@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo CAMS IoT - Creando Archivos
echo ========================================
echo.

set TARGET_PATH=E:\CAMS_IoT_Prototype

echo Ubicacion: %TARGET_PATH%
echo.

if not exist "%TARGET_PATH%" mkdir "%TARGET_PATH%"
if not exist "%TARGET_PATH%\firmware" mkdir "%TARGET_PATH%\firmware"
if not exist "%TARGET_PATH%\backend" mkdir "%TARGET_PATH%\backend"
if not exist "%TARGET_PATH%\dashboard\static" mkdir "%TARGET_PATH%\dashboard\static"
if not exist "%TARGET_PATH%\docs" mkdir "%TARGET_PATH%\docs"
if not exist "%TARGET_PATH%\tests" mkdir "%TARGET_PATH%\tests"

echo Creando archivos de firmware...
echo.

REM calibracion_sensor_raw.ino
(
echo // Calibracion - Lectura cruda del sensor MPXV7002GP
echo // Paso 51 de la Guia Interdisciplinaria
echo const int SENSOR_PIN = 34;
echo void setup(^) {
echo   Serial.begin(115200^);
echo   delay(1000^);
echo   Serial.println("Iniciando calibracion"^);
echo   analogReadResolution(12^);
echo }
echo void loop(^) {
echo   int rawValue = analogRead(SENSOR_PIN^);
echo   Serial.print(millis(^)^);
echo   Serial.print(", "^);
echo   Serial.println(rawValue^);
echo   delay(200^);
echo }
) > "%TARGET_PATH%\firmware\calibracion_sensor_raw.ino"
echo [OK] calibracion_sensor_raw.ino

REM secrets.h.template
(
echo #ifndef SECRETS_H
echo #define SECRETS_H
echo #define WIFI_SSID "TU_RED_WIFI"
echo #define WIFI_PASSWORD "TU_CONTRASEÑA"
echo #endif
) > "%TARGET_PATH%\firmware\secrets.h.template"
echo [OK] secrets.h.template

REM calibracion_presion.ino
(
echo // Calibracion - Conversion ADC a Presion
echo // Paso 57 de la Guia Interdisciplinaria
echo const float ADC_OFFSET = 2047;
echo const float M_FACTOR = 0.0215;
echo const float B_OFFSET = 0.0;
echo const int SENSOR_PIN = 34;
echo float presiones[5] = {0};
echo int indicePresion = 0;
echo void setup(^) {
echo   Serial.begin(115200^);
echo   delay(1000^);
echo   Serial.println("Calibracion - Presion"^);
echo   analogReadResolution(12^);
echo }
echo float leerPresionFiltrada(^) {
echo   int adcValue = analogRead(SENSOR_PIN^);
echo   float presion = M_FACTOR * (adcValue - ADC_OFFSET^) + B_OFFSET;
echo   presiones[indicePresion] = presion;
echo   indicePresion = (indicePresion + 1^) %% 5;
echo   float suma = 0;
echo   for (int i = 0; i ^< 5; i++^) suma += presiones[i];
echo   return suma / 5;
echo }
echo void loop(^) {
echo   Serial.printf("Presion: %%.2f cmH2O\n", leerPresionFiltrada(^)^);
echo   delay(200^);
echo }
) > "%TARGET_PATH%\firmware\calibracion_presion.ino"
echo [OK] calibracion_presion.ino

REM cams_pressure_monitor.ino
(
echo // CAMS IoT - Firmware Completo ESP32
echo #include ^<WiFi.h^>
echo #include ^<HTTPClient.h^>
echo const float ADC_OFFSET = 2047;
echo const float M_FACTOR = 0.0215;
echo const float B_OFFSET = 0.0;
echo const char* WIFI_SSID = "TU_RED_WIFI";
echo const char* WIFI_PASSWORD = "TU_CONTRASEÑA";
echo const char* SERVER_URL = "http://192.168.1.100:5000/api/sensor";
echo const int SENSOR_PIN = 34;
echo const int LED_BUILTIN = 2;
echo const float PRESION_MIN_NORMAL = 5.0;
echo const float PRESION_MAX_NORMAL = 35.0;
echo float presiones[5] = {0};
echo int indicePresion = 0;
echo void setup(^) {
echo   Serial.begin(115200^);
echo   delay(1000^);
echo   Serial.println("CAMS IoT iniciando..."^);
echo   analogReadResolution(12^);
echo   pinMode(LED_BUILTIN, OUTPUT^);
echo   digitalWrite(LED_BUILTIN, LOW^);
echo   conectarWiFi(^);
echo   Serial.println("Sistema listo"^);
echo }
echo void conectarWiFi(^) {
echo   WiFi.mode(WIFI_STA^);
echo   WiFi.begin(WIFI_SSID, WIFI_PASSWORD^);
echo   int intentos = 0;
echo   while (WiFi.status(^) != WL_CONNECTED ^&^& intentos ^< 20^) {
echo     delay(500^);
echo     digitalWrite(LED_BUILTIN, HIGH^);
echo     delay(100^);
echo     digitalWrite(LED_BUILTIN, LOW^);
echo     intentos++;
echo   }
echo   if (WiFi.status(^) == WL_CONNECTED^) {
echo     digitalWrite(LED_BUILTIN, HIGH^);
echo     Serial.println("Conectado a WiFi"^);
echo   }
echo }
echo float leerPresionFiltrada(^) {
echo   int adcValue = analogRead(SENSOR_PIN^);
echo   float presion = M_FACTOR * (adcValue - ADC_OFFSET^) + B_OFFSET;
echo   presiones[indicePresion] = presion;
echo   indicePresion = (indicePresion + 1^) %% 5;
echo   float suma = 0;
echo   for (int i = 0; i ^< 5; i++^) suma += presiones[i];
echo   return suma / 5;
echo }
echo String evaluarAlerta(float presion^) {
echo   if (presion ^< PRESION_MIN_NORMAL^) return "FUGA";
echo   if (presion ^> PRESION_MAX_NORMAL^) return "OBSTRUCCIÓN";
echo   return "NORMAL";
echo }
echo void enviarDatos(float presion, String alerta^) {
echo   if (WiFi.status(^) == WL_CONNECTED^) {
echo     HTTPClient http;
echo     http.begin(SERVER_URL^);
echo     http.addHeader("Content-Type", "application/json"^);
echo     String payload = "{\"presion\":" + String(presion, 2^) + ",\"alerta\":\"" + alerta + "\"}"^;
echo     http.POST(payload^);
echo     http.end(^);
echo   }
echo }
echo void loop(^) {
echo   float presion = leerPresionFiltrada(^);
echo   String alerta = evaluarAlerta(presion^);
echo   Serial.printf("Presion: %%.2f cmH2O ^| Alerta: %%s\n", presion, alerta.c_str(^)^);
echo   enviarDatos(presion, alerta^);
echo   delay(200^);
echo }
) > "%TARGET_PATH%\firmware\cams_pressure_monitor.ino"
echo [OK] cams_pressure_monitor.ino

echo.
echo Creando archivos de backend...
echo.

REM requirements.txt
(
echo Flask==2.3.3
echo Flask-CORS==4.0.0
echo Werkzeug==2.3.7
) > "%TARGET_PATH%\backend\requirements.txt"
echo [OK] requirements.txt

REM database.py - ESCRITO LINEA POR LINEA
(
echo import sqlite3
echo import os
echo.
echo DB_PATH = os.path.join(os.path.dirname(__file__^), 'sensor_data.db'^)
echo.
echo def init_db(^):
echo.  conn = sqlite3.connect(DB_PATH^)
echo.  cursor = conn.cursor(^)
echo.  cursor.execute('CREATE TABLE IF NOT EXISTS pressure_readings (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, pressure_cmh2o REAL NOT NULL, alert_level TEXT NOT NULL)'^)
echo.  cursor.execute('CREATE TABLE IF NOT EXISTS alert_events (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, alert_type TEXT NOT NULL, pressure_value REAL)'^)
echo.  conn.commit(^)
echo.  conn.close(^)
echo.  print('Base de datos inicializada'^)
echo.
echo def insert_pressure_reading(pressure_cmh2o, alert_level^):
echo.  conn = sqlite3.connect(DB_PATH^)
echo.  cursor = conn.cursor(^)
echo.  cursor.execute('INSERT INTO pressure_readings (pressure_cmh2o, alert_level^) VALUES (?, ?)'^, (pressure_cmh2o, alert_level^)^)
echo.  conn.commit(^)
echo.  conn.close(^)
echo.
echo def get_latest_reading(^):
echo.  conn = sqlite3.connect(DB_PATH^)
echo.  conn.row_factory = sqlite3.Row
echo.  cursor = conn.cursor(^)
echo.  cursor.execute('SELECT * FROM pressure_readings ORDER BY timestamp DESC LIMIT 1'^)
echo.  row = cursor.fetchone(^)
echo.  conn.close(^)
echo.  return dict(row^) if row else None
echo.
echo def get_pressure_history(limit=30^):
echo.  conn = sqlite3.connect(DB_PATH^)
echo.  conn.row_factory = sqlite3.Row
echo.  cursor = conn.cursor(^)
echo.  cursor.execute('SELECT * FROM pressure_readings ORDER BY timestamp DESC LIMIT ?'^, (limit,^)^)
echo.  rows = cursor.fetchall(^)
echo.  conn.close(^)
echo.  return [dict(row^) for row in reversed(rows^)]
echo.
echo def get_alert_history(limit=10^):
echo.  conn = sqlite3.connect(DB_PATH^)
echo.  conn.row_factory = sqlite3.Row
echo.  cursor = conn.cursor(^)
echo.  cursor.execute('SELECT * FROM alert_events ORDER BY timestamp DESC LIMIT ?'^, (limit,^)^)
echo.  rows = cursor.fetchall(^)
echo.  conn.close(^)
echo.  return [dict(row^) for row in reversed(rows^)]
echo.
echo if __name__ == '__main__':
echo.  init_db(^)
) > "%TARGET_PATH%\backend\database.py"
echo [OK] database.py

REM app.py
(
echo from flask import Flask, request, jsonify
echo from flask_cors import CORS
echo from database import *
echo import sqlite3
echo.
echo app = Flask(__name__^)
echo CORS(app^)
echo init_db(^)
echo.
echo @app.route('/api/sensor'^, methods=['POST']^)
echo def receive_sensor_data(^):
echo.  try:
echo.   data = request.get_json(^)
echo.   presion = float(data['presion']^)
echo.   alerta = data['alerta'].upper(^)
echo.   insert_pressure_reading(presion, alerta^)
echo.   if alerta in ['FUGA'^, 'OBSTRUCCIÓN']:
echo.    conn = sqlite3.connect('sensor_data.db'^)
echo.    cursor = conn.cursor(^)
echo.    cursor.execute('INSERT INTO alert_events (alert_type, pressure_value^) VALUES (?, ?)'^, (alerta, presion^)^)
echo.    conn.commit(^)
echo.    conn.close(^)
echo.   return jsonify({'status': 'ok'}^), 200
echo.  except Exception as e:
echo.   return jsonify({'status': 'error'}^), 500
echo.
echo @app.route('/api/sensor/latest'^, methods=['GET']^)
echo def get_latest(^):
echo.  latest = get_latest_reading(^)
echo.  return jsonify({'data': latest}^) if latest else (jsonify({}^), 404^)
echo.
echo @app.route('/api/sensor/history'^, methods=['GET']^)
echo def get_history(^):
echo.  limit = request.args.get('limit'^, 30, int^)
echo.  return jsonify({'data': get_pressure_history(limit^)})
echo.
echo @app.route('/api/alerts'^, methods=['GET']^)
echo def get_alerts(^):
echo.  limit = request.args.get('limit'^, 10, int^)
echo.  return jsonify({'data': get_alert_history(limit^)})
echo.
echo @app.route('/api/health'^, methods=['GET']^)
echo def health(^):
echo.  return jsonify({'status': 'ok'}^)
echo.
echo if __name__ == '__main__':
echo.  app.run(host='0.0.0.0'^, port=5000, debug=True^)
) > "%TARGET_PATH%\backend\app.py"
echo [OK] app.py

REM simulator.py
(
echo import requests
echo import time
echo import random
echo.
echo SERVER_URL = "http://localhost:5000/api/sensor"
echo.
echo def send_data(pressure, alert_level^):
echo.  try:
echo.   payload = {'presion': pressure, 'alerta': alert_level}
echo.   response = requests.post(SERVER_URL, json=payload, timeout=5^)
echo.   return response.status_code == 200
echo.  except:
echo.   return False
echo.
echo def calculate_alert(pressure^):
echo.  if pressure ^< 5.0:
echo.   return 'FUGA'
echo.  elif pressure ^> 35.0:
echo.   return 'OBSTRUCCIÓN'
echo.  return 'NORMAL'
echo.
echo print("Simulador ESP32 - CAMS IoT"^)
echo choice = input("Elegir escenario (1-NORMAL, 2-LEAK, 3-OBSTRUCTION^): "^).strip(^)
echo scenarios = {'1': ('NORMAL'^, 20, 1.5^), '2': ('LEAK'^, 3, 0.5^), '3': ('OBSTRUCTION'^, 42, 2^)}
echo scenario_name, base_pressure, variance = scenarios.get(choice, scenarios['1']^)
echo print(f"\nSimulando: {scenario_name}\nEnviando datos...\n"^)
echo iteration = 0
echo try:
echo.  while True:
echo.   iteration += 1
echo.   pressure = base_pressure + random.uniform(-variance, variance^)
echo.   pressure = max(-5, min(50, pressure^)^)
echo.   alert_level = calculate_alert(pressure^)
echo.   success = send_data(pressure, alert_level^)
echo.   status = "OK" if success else "FAIL"
echo.   print(f"[{iteration}] {status} ^| Presion: {pressure:6.2f} cmH2O"^)
echo.   time.sleep(1^)
echo except KeyboardInterrupt:
echo.  print("\n\nSimulacion detenida"^)
) > "%TARGET_PATH%\backend\simulator.py"
echo [OK] simulator.py

echo.
echo Creando archivos de dashboard...
echo.

REM index.html
(
echo ^<!DOCTYPE html^>
echo ^<html lang="es"^>
echo ^<head^>
echo ^<meta charset="UTF-8"^>
echo ^<title^>CAMS IoT^</title^>
echo ^<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"^>^</script^>
echo ^<link rel="stylesheet" href="static/style.css"^>
echo ^</head^>
echo ^<body^>
echo ^<header class="header"^>^<h1^>CAMS IoT Pressure Monitor^</h1^>^</header^>
echo ^<main class="container"^>
echo ^<div class="card"^>
echo ^<h2^>Presion Actual^</h2^>
echo ^<p style="font-size: 3rem;"^>^<span id="pressure"^>--^</span^> cmH2O^</p^>
echo ^</div^>
echo ^<div class="card"^>
echo ^<h2^>Estado^</h2^>
echo ^<p id="status"^>ESPERANDO^</p^>
echo ^</div^>
echo ^</main^>
echo ^<script src="static/dashboard.js"^>^</script^>
echo ^</body^>
echo ^</html^>
) > "%TARGET_PATH%\dashboard\index.html"
echo [OK] index.html

REM style.css
(
echo * { margin: 0; padding: 0; }
echo body { font-family: Arial; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%^); color: #333; padding: 20px; }
echo .header { text-align: center; color: white; margin-bottom: 30px; }
echo .container { max-width: 1200px; margin: 0 auto; }
echo .card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1^); }
) > "%TARGET_PATH%\dashboard\static\style.css"
echo [OK] style.css

REM dashboard.js
(
echo const CONFIG = { backendUrl: 'http://localhost:5000', updateInterval: 2000 };
echo document.addEventListener('DOMContentLoaded', function(^) {
echo.  setInterval(updateData, CONFIG.updateInterval^);
echo }^);
echo async function updateData(^) {
echo.  try {
echo.   let resp = await fetch(CONFIG.backendUrl + '/api/sensor/latest'^);
echo.   if (resp.ok^) {
echo.    let data = await resp.json(^);
echo.    if (data.data^) {
echo.     document.getElementById('pressure'^).textContent = data.data.pressure_cmh2o.toFixed(2^);
echo.     document.getElementById('status'^).textContent = data.data.alert_level;
echo.    }
echo.   }
echo.  } catch (e^) {
echo.   console.log('Error'^);
echo.  }
echo }
) > "%TARGET_PATH%\dashboard\static\dashboard.js"
echo [OK] dashboard.js

echo.
echo Creando archivos de configuracion...
echo.

REM .gitignore
(
echo __pycache__/
echo *.pyc
echo venv/
echo .vscode/
echo sensor_data.db
echo *.db
echo secrets.h
echo .env
echo *.log
) > "%TARGET_PATH%\.gitignore"
echo [OK] .gitignore

REM README.md
(
echo # CAMS IoT Pressure Monitor
echo.
echo Sistema de monitoreo en tiempo real de presion.
echo.
echo ## Inicio Rapido
echo.
echo ### Backend
echo cd backend
echo python -m venv venv
echo venv\Scripts\activate
echo pip install -r requirements.txt
echo python database.py
echo python app.py
echo.
echo ### Dashboard
echo cd dashboard
echo python -m http.server 8000
echo.
echo ### Simulador
echo cd backend
echo python simulator.py
) > "%TARGET_PATH%\README.md"
echo [OK] README.md

echo.
echo Inicializando Git...
if not exist "%TARGET_PATH%\.git" (
    cd /d "%TARGET_PATH%"
    git init >nul 2>&1
    git add . >nul 2>&1
    git commit -m "Initial commit" >nul 2>&1
    echo [OK] Git inicializado
) else (
    echo [OK] Git ya existe
)

echo.
echo ========================================
echo EXITO - TODOS LOS ARCHIVOS CREADOS!
echo ========================================
echo.
echo Ubicacion: %TARGET_PATH%
echo.
echo Archivos generados:
echo   - 4 archivos firmware (.ino)
echo   - 4 archivos backend (.py)
echo   - 3 archivos dashboard
echo   - .gitignore, README.md
echo.
echo Ver carpeta: %TARGET_PATH%
echo.
echo ========================================
echo Presiona cualquier tecla para cerrar...
echo ========================================
pause
