from flask import Flask, request, jsonify
from flask_cors import CORS
from database import *
import sqlite3

app = Flask(__name__)
CORS(app)

init_db()

@app.route('/api/sensor', methods=['POST'])
def receive_sensor_data():
    try:
        data = request.get_json()
        presion = float(data['presion'])
        alerta = data['alerta'].upper()
        insert_pressure_reading(presion, alerta)
        if alerta in ['FUGA', 'OBSTRUCCIÓN']:
            conn = sqlite3.connect('sensor_data.db')
            cursor = conn.cursor()
            cursor.execute('INSERT INTO alert_events (alert_type, pressure_value) VALUES (?, ?)', 
                         (alerta, presion))
            conn.commit()
            conn.close()
        return jsonify({'status': 'ok'}), 200
    except Exception as e:
        return jsonify({'status': 'error'}), 500

@app.route('/api/sensor/latest', methods=['GET'])
def get_latest():
    latest = get_latest_reading()
    return jsonify({'data': latest}) if latest else (jsonify({}), 404)

@app.route('/api/sensor/history', methods=['GET'])
def get_history():
    limit = request.args.get('limit', 30, int)
    return jsonify({'data': get_pressure_history(limit)})

@app.route('/api/alerts', methods=['GET'])
def get_alerts():
    limit = request.args.get('limit', 10, int)
    return jsonify({'data': get_alert_history(limit)})

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
