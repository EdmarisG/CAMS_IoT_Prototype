\# CAMS IoT - Prototipo de Monitoreo de Presión



\## Descripción



Sistema IoT para monitoreo de presión en ventilación simulada.



\## Estructura del Proyecto



\- `firmware/` – Código del ESP32 (lectura de sensor, calibración, Wi-Fi, envío a backend)

\- `backend/` – API REST con Flask (recepción de datos, almacenamiento SQLite, endpoints)

\- `dashboard/` – Frontend web (HTML, CSS, JS, gráficos en tiempo real)



\## Archivos Importantes (Configuración y exclusiones)



\- `.gitignore` – Archivos que no se suben a Git.

\- `.exclude` – Archivos que no se incluyen en backups manuales.

\- `firmware/secrets.h.template` – Plantilla de credenciales (Wi-Fi, URL del servidor).



\---



\## Firmware (ESP32)



\### `firmware/calibracion\_sensor\_raw.ino`

Lee valores crudos del ADC de 12 bits del sensor MPXV7002GP conectado a GPIO34.  

Envía por Serial: `tiempo\_ms` y `valor\_adc`.



\### `firmware/calibracion\_presion.ino`

Conversión lineal: `Presion = m × (ADC - offset) + b`.  

Incluye constantes de calibración (`ADC\_OFFSET`, `M\_FACTOR`, `B\_OFFSET`), filtro de media móvil (5 muestras) y conversión a cmH₂O.



\### `firmware/cams\_pressure\_monitor.ino` – Firmware principal

\- Configuración de pines y calibración.

\- Buffer circular para resiliencia de red.

\- Lectura, filtrado y detección de anomalías (`FUGA`, `OBSTRUCCIÓN`, `NORMAL`).

\- Conexión Wi-Fi y transmisión a backend.



\*\*⚠️ Requiere edición:\*\*  

`ADC\_OFFSET`, `M\_FACTOR`, `B\_OFFSET`, `WIFI\_SSID`, `WIFI\_PASSWORD`, `SERVER\_URL`



\---



\## Backend (API REST con Flask)



\### `backend/requirements.txt`

Dependencias Python:



flask==2.3.3

flask-cors==4.0.0

werkzeug==2.3.7





\### `backend/database.py`

Esquema SQLite con tablas:

\- `pressure\_readings`: `id`, `timestamp`, `pressure\_cmh2o`, `alert\_level`, `device\_id`

\- `alert\_events`: `id`, `timestamp`, `alert\_type`, `pressure\_value`, `acknowledged`



Funciones:

\- `init\_db()` – Crear tablas si no existen.

\- `insert\_reading(presion, alerta)` – Guardar lectura.

\- `get\_latest()` – Última lectura.

\- `get\_history(limit)` – Historial de presiones.

\- `get\_alerts(limit)` – Historial de alertas.



\### `backend/app.py` – API REST

Endpoints disponibles:



| Método | Endpoint | Descripción |

|--------|----------|-------------|

| POST   | `/api/sensor` | Recibir datos del ESP32 |

| GET    | `/api/sensor/latest` | Última lectura |

| GET    | `/api/sensor/history` | Historial de presiones (con límite) |

| GET    | `/api/alerts` | Historial de alertas |

| GET    | `/api/health` | Estado del servidor |



Características:

\- CORS habilitado para el dashboard.

\- Validación de entrada.

\- Almacenamiento automático en SQLite.

\- Respuestas JSON.



\### Instalación y uso (Backend)

```bash

cd backend

pip install -r requirements.txt

python app.py



\#### El servidor correrá en http://localhost:5000.

\#### Puedes probar los endpoints con curl o Postman.



