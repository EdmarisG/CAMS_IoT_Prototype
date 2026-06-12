// CAMS IoT - Firmware Completo ESP32
#include <WiFi.h>
#include <HTTPClient.h>
const float ADC_OFFSET = 2047;
const float M_FACTOR = 0.0215;
const float B_OFFSET = 0.0;
const char* WIFI_SSID = "TU_RED_WIFI";
const char* WIFI_PASSWORD = "TU_CONTRASEÑA";
const char* SERVER_URL = "http://192.168.1.100:5000/api/sensor";
const int SENSOR_PIN = 34;
const int LED_BUILTIN = 2;
const float PRESION_MIN_NORMAL = 5.0;
const float PRESION_MAX_NORMAL = 35.0;
float presiones[5] = {0};
int indicePresion = 0;
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("CAMS IoT iniciando...");
  analogReadResolution(12);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  conectarWiFi();
  Serial.println("Sistema listo");
}
void conectarWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int intentos = 0;
  while (WiFi.status() = WL_CONNECTED && intentos < 20) {
    delay(500);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);
    intentos++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.println("Conectado a WiFi");
  }
}
float leerPresionFiltrada() {
  int adcValue = analogRead(SENSOR_PIN);
  float presion = M_FACTOR * (adcValue - ADC_OFFSET) + B_OFFSET;
  presiones[indicePresion] = presion;
  indicePresion = (indicePresion + 1) % 5;
  float suma = 0;
  for (int i = 0; i < 5; i++) suma += presiones[i];
  return suma / 5;
}
String evaluarAlerta(float presion) {
  if (presion < PRESION_MIN_NORMAL) return "FUGA";
  if (presion > PRESION_MAX_NORMAL) return "OBSTRUCCIÓN";
  return "NORMAL";
}
void enviarDatos(float presion, String alerta) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(SERVER_URL);
    http.addHeader("Content-Type", "application/json");
    String payload = "{\"presion\":" + String(presion, 2) + ",\"alerta\":\"" + alerta + "\"}";
    http.POST(payload);
    http.end();
  }
}
void loop() {
  float presion = leerPresionFiltrada();
  String alerta = evaluarAlerta(presion);
  Serial.printf("Presion: %.2f cmH2O ^| Alerta: %s\n", presion, alerta.c_str());
  enviarDatos(presion, alerta);
  delay(200);
}
