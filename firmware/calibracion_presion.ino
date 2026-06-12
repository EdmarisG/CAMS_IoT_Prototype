// Calibracion - Conversion ADC a Presion
// Paso 57 de la Guia Interdisciplinaria
const float ADC_OFFSET = 2047;
const float M_FACTOR = 0.0215;
const float B_OFFSET = 0.0;
const int SENSOR_PIN = 34;
float presiones[5] = {0};
int indicePresion = 0;
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Calibracion - Presion");
  analogReadResolution(12);
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
void loop() {
  Serial.printf("Presion: %.2f cmH2O\n", leerPresionFiltrada());
  delay(200);
}
