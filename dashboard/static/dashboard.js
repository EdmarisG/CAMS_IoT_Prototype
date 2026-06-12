const CONFIG = {
    backendUrl: 'http://localhost:5000',
    updateInterval: 2000,
    maxDataPoints: 30,
    maxAlerts: 10
};

let pressureChart = null;

document.addEventListener('DOMContentLoaded', function() {
    initChart();
    loadInitialData();
    startAutoUpdate();
});

function initChart() {
    const ctx = document.getElementById('pressureChart').getContext('2d');
    pressureChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Presion (cmH2O)',
                data: [],
                borderColor: '#667eea',
                backgroundColor: 'rgba(102, 126, 234, 0.1)',
                borderWidth: 2,
                tension: 0.4,
                fill: true,
                pointRadius: 5,
                pointBackgroundColor: '#667eea'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: false,
                    min: -10,
                    max: 50
                }
            }
        }
    });
}

async function loadInitialData() {
    await updateCurrentPressure();
    await updatePressureChart();
    await updateAlertHistory();
}

async function updateCurrentPressure() {
    try {
        const response = await fetch(CONFIG.backendUrl + '/api/sensor/latest');
        const data = await response.json();
        
        if (data.data) {
            document.getElementById('current-pressure').textContent = data.data.pressure_cmh2o.toFixed(2);
            document.getElementById('update-time').textContent = new Date(data.data.timestamp).toLocaleTimeString();
            updateAlertBadge(data.data.alert_level);
        }
    } catch (e) {
        console.log('Error');
    }
}

async function updatePressureChart() {
    try {
        const response = await fetch(CONFIG.backendUrl + '/api/sensor/history?limit=' + CONFIG.maxDataPoints);
        const data = await response.json();
        
        if (data.data) {
            const labels = [];
            const pressures = [];
            
            data.data.forEach(reading => {
                const time = new Date(reading.timestamp).toLocaleTimeString();
                labels.push(time);
                pressures.push(reading.pressure_cmh2o);
            });
            
            pressureChart.data.labels = labels;
            pressureChart.data.datasets[0].data = pressures;
            pressureChart.update('none');
            
            updateStats(pressures);
        }
    } catch (e) {
        console.log('Error');
    }
}

async function updateAlertHistory() {
    try {
        const response = await fetch(CONFIG.backendUrl + '/api/alerts?limit=' + CONFIG.maxAlerts);
        const data = await response.json();
        const container = document.getElementById('alerts-container');
        
        if (data.data && data.data.length > 0) {
            container.innerHTML = '';
            data.data.forEach(alert => {
                const div = document.createElement('div');
                div.className = 'alert-item ' + alert.alert_type.toLowerCase();
                div.innerHTML = '<strong>' + alert.alert_type + '</strong><br><small>' + alert.pressure_value + ' cmH2O</small>';
                container.appendChild(div);
            });
        }
    } catch (e) {
        console.log('Error');
    }
}

function updateAlertBadge(alertLevel) {
    const badge = document.getElementById('alert-badge');
    const text = document.getElementById('alert-text');
    
    badge.className = 'alert-badge';
    const lower = alertLevel.toLowerCase();
    
    if (lower === 'fuga') {
        badge.classList.add('leak');
        text.textContent = 'FUGA';
    } else if (lower === 'obstruccion') {
        badge.classList.add('obstruction');
        text.textContent = 'OBSTRUCCION';
    } else if (lower === 'normal') {
        badge.classList.add('normal');
        text.textContent = 'NORMAL';
    }
}

function updateStats(pressures) {
    if (pressures.length > 0) {
        const min = Math.min(...pressures);
        const max = Math.max(...pressures);
        const avg = pressures.reduce((a, b) => a + b) / pressures.length;
        
        document.getElementById('stat-min').textContent = min.toFixed(2);
        document.getElementById('stat-max').textContent = max.toFixed(2);
        document.getElementById('stat-avg').textContent = avg.toFixed(2);
    }
}

function startAutoUpdate() {
    setInterval(async () => {
        await updateCurrentPressure();
        await updatePressureChart();
        await updateAlertHistory();
    }, CONFIG.updateInterval);
}
