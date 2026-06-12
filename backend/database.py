import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'sensor_data.db')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS pressure_readings 
    (id INTEGER PRIMARY KEY AUTOINCREMENT, 
     timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, 
     pressure_cmh2o REAL NOT NULL, 
     alert_level TEXT NOT NULL)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS alert_events 
    (id INTEGER PRIMARY KEY AUTOINCREMENT, 
     timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, 
     alert_type TEXT NOT NULL, 
     pressure_value REAL)''')
    conn.commit()
    conn.close()
    print('Base de datos inicializada')

def insert_pressure_reading(pressure_cmh2o, alert_level):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('INSERT INTO pressure_readings (pressure_cmh2o, alert_level) VALUES (?, ?)', 
                   (pressure_cmh2o, alert_level))
    conn.commit()
    conn.close()

def get_latest_reading():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM pressure_readings ORDER BY timestamp DESC LIMIT 1')
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def get_pressure_history(limit=30):
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM pressure_readings ORDER BY timestamp DESC LIMIT ?', (limit,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in reversed(rows)]

def get_alert_history(limit=10):
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM alert_events ORDER BY timestamp DESC LIMIT ?', (limit,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in reversed(rows)]

if __name__ == '__main__':
    init_db()
