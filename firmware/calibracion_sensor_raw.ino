// Calibracion - Lectura cruda del sensor MPXV7002GP
// Paso 51 de la Guia Interdisciplinaria
const int SENSOR_PIN = 34;
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Iniciando calibracion");
  analogReadResolution(12);
}
void loop() {
  int rawValue = analogRead(SENSOR_PIN);
  Serial.print(millis());
  Serial.print(", ");
  Serial.println(rawValue);
  delay(200);
}
