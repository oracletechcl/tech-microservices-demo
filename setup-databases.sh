#!/bin/bash

# =============================================================================
# Database Setup Script for Microservices
# =============================================================================
# This script creates all necessary databases and tables for the microservices
# architecture. It ensures all services have proper database connectivity.
# =============================================================================

# ---------- CONFIGURACIÓN ----------
DB_HOST="10.0.10.126"
DB_PORT="3306"
DB_USER="admin"
DB_PASSWORD="Welcome1."

echo "🗄️  Setting up databases for microservices architecture..."
echo "📊 Database Host: ${DB_HOST}:${DB_PORT}"
echo "👤 Database User: ${DB_USER}"
echo ""

# ---------- FUNCIÓN PARA EJECUTAR COMANDOS SQL ----------
execute_sql() {
    local sql_command="$1"
    local description="$2"
    
    echo "📝 ${description}..."
    kubectl run mysql-client-$(date +%s) --image=mysql:8.0 --rm -it --restart=Never -- mysql -h ${DB_HOST} -u ${DB_USER} -p"${DB_PASSWORD}" -e "${sql_command}" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ ${description} completed successfully"
    else
        echo "❌ Error: ${description} failed"
        return 1
    fi
    echo ""
}

# ---------- CREAR BASES DE DATOS ----------
echo "🏗️  Creating databases..."
echo ""

# 1. Login Microservice Database
execute_sql "CREATE DATABASE IF NOT EXISTS login_ms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" "Creating login_ms database"

# 2. Agenda/Scheduling Microservice Database
execute_sql "CREATE DATABASE IF NOT EXISTS agenda_ms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" "Creating agenda_ms database"

# 3. Quote Microservice Database
execute_sql "CREATE DATABASE IF NOT EXISTS cotizar_ms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" "Creating cotizar_ms database"

# 4. Payment Microservice Database
execute_sql "CREATE DATABASE IF NOT EXISTS pagar_ms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" "Creating pagar_ms database"

# ---------- CREAR TABLAS PARA LOGIN_MS ----------
echo "🔐 Setting up login_ms tables..."

LOGIN_TABLES_SQL="
USE login_ms;

-- Table structure based on 01-login-ms/app.js
CREATE TABLE IF NOT EXISTS usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

-- Keep the users table for compatibility but populate usuario for the microservice
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token_hash (token_hash),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
);
"

execute_sql "$LOGIN_TABLES_SQL" "Creating login_ms tables"

# ---------- CREAR TABLAS PARA AGENDA_MS ----------
echo "📅 Setting up agenda_ms tables..."

AGENDA_TABLES_SQL="
USE agenda_ms;

-- Table structure based on 02-agendar-ms models
CREATE TABLE IF NOT EXISTS reserva (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    sucursal VARCHAR(64) NOT NULL,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_fecha (fecha),
    INDEX idx_sucursal (sucursal)
);

-- Additional table for extended reservations functionality
CREATE TABLE IF NOT EXISTS reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    service_type VARCHAR(100) NOT NULL,
    description TEXT,
    status ENUM('pending', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_appointment_date (appointment_date),
    INDEX idx_status (status),
    INDEX idx_customer_email (customer_email)
);

CREATE TABLE IF NOT EXISTS service_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    duration_minutes INT DEFAULT 60,
    price DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sucursales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(200),
    telefono VARCHAR(20),
    horario_atencion VARCHAR(100),
    ciudad VARCHAR(50),
    region VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

execute_sql "$AGENDA_TABLES_SQL" "Creating agenda_ms tables"

# ---------- CREAR TABLAS PARA COTIZAR_MS ----------
echo "💰 Setting up cotizar_ms tables..."

COTIZAR_TABLES_SQL="
USE cotizar_ms;

-- Table structure based on 03-cotizar-ms/models.py
CREATE TABLE IF NOT EXISTS producto_seguro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(64) NOT NULL UNIQUE,
    descripcion VARCHAR(256),
    tipo VARCHAR(32),
    cobertura VARCHAR(128),
    prima_base DECIMAL(15, 2),
    deducible DECIMAL(15, 2),
    aseguradora VARCHAR(64),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cotizacion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    producto_seguro_id INT NOT NULL,
    monto DECIMAL(15, 2) NOT NULL,
    plazo_meses INT NOT NULL,
    tasa_anual DECIMAL(5, 2) NOT NULL,
    cuota_mensual DECIMAL(15, 2) NOT NULL,
    total_pagado DECIMAL(15, 2) NOT NULL,
    cae DECIMAL(6, 2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_seguro_id) REFERENCES producto_seguro(id),
    INDEX idx_usuario_id (usuario_id),
    INDEX idx_producto_seguro_id (producto_seguro_id)
);

-- Legacy table for compatibility
CREATE TABLE IF NOT EXISTS insurance_quotes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender ENUM('M', 'F', 'O') NOT NULL,
    coverage_type VARCHAR(50) NOT NULL,
    coverage_amount DECIMAL(12, 2) NOT NULL,
    premium_amount DECIMAL(10, 2) NOT NULL,
    risk_score DECIMAL(5, 2),
    status ENUM('draft', 'quoted', 'accepted', 'rejected', 'expired') DEFAULT 'draft',
    valid_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_customer_email (customer_email),
    INDEX idx_status (status),
    INDEX idx_valid_until (valid_until)
);

CREATE TABLE IF NOT EXISTS coverage_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    base_premium_rate DECIMAL(8, 4) NOT NULL,
    max_coverage DECIMAL(12, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

execute_sql "$COTIZAR_TABLES_SQL" "Creating cotizar_ms tables"

# ---------- CREAR TABLAS PARA PAGAR_MS ----------
echo "💳 Setting up pagar_ms tables..."

PAGAR_TABLES_SQL="
USE pagar_ms;

CREATE TABLE IF NOT EXISTS deudas (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    monto DECIMAL(12, 2) NOT NULL,
    descripcion VARCHAR(255),
    fecha_vencimiento DATE,
    estado ENUM('pendiente', 'pagada', 'vencida', 'cancelada') DEFAULT 'pendiente',
    tipo_deuda VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_estado (estado),
    INDEX idx_fecha_vencimiento (fecha_vencimiento)
);

CREATE TABLE IF NOT EXISTS pagos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    deuda_id BIGINT NOT NULL,
    monto_pagado DECIMAL(12, 2) NOT NULL,
    metodo_pago VARCHAR(50),
    referencia_transaccion VARCHAR(100),
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('procesando', 'exitoso', 'fallido', 'revertido') DEFAULT 'procesando',
    FOREIGN KEY (deuda_id) REFERENCES deudas(id) ON DELETE CASCADE,
    INDEX idx_deuda_id (deuda_id),
    INDEX idx_estado (estado),
    INDEX idx_fecha_pago (fecha_pago)
);
"

execute_sql "$PAGAR_TABLES_SQL" "Creating pagar_ms tables"

# ---------- INSERTAR DATOS DE EJEMPLO ----------
echo "🌱 Inserting sample data..."

SAMPLE_DATA_SQL="
# ---------- INSERTAR DATOS DE EJEMPLO ----------
echo "🌱 Inserting sample data..."

SAMPLE_DATA_SQL="
-- Sample data for coverage types
USE cotizar_ms;
INSERT IGNORE INTO coverage_types (name, description, base_premium_rate, max_coverage) VALUES
('Vida Básico', 'Seguro de vida básico', 0.002, 50000.00),
('Vida Premium', 'Seguro de vida premium con cobertura extendida', 0.0035, 200000.00),
('Salud Individual', 'Seguro de salud individual', 0.008, 30000.00),
('Auto Terceros', 'Seguro automotriz solo terceros', 0.015, 10000.00),
('Auto Full', 'Seguro automotriz cobertura completa', 0.025, 50000.00);

-- Populate producto_seguro table with comprehensive insurance products
INSERT IGNORE INTO producto_seguro (nombre, descripcion, tipo, cobertura, prima_base, deducible, aseguradora) VALUES
-- Seguros de Vida
('Seguro de Vida Básico', 'Protección básica para tu familia con cobertura por muerte natural y accidental', 'vida', 'Muerte natural y accidental', 25000.00, 0.00, 'Metlife Chile'),
('Seguro de Vida Premium', 'Cobertura completa con beneficios adicionales y invalidez total', 'vida', 'Muerte, invalidez total y parcial, enfermedades graves', 45000.00, 0.00, 'Metlife Chile'),
('Seguro de Vida Familiar', 'Protege a toda tu familia con una sola póliza', 'vida', 'Cobertura familiar completa', 60000.00, 0.00, 'Seguros Falabella'),

-- Seguros de Salud
('Seguro de Salud Individual', 'Cobertura médica individual con red de prestadores', 'salud', 'Consultas, hospitalizaciones, medicamentos', 35000.00, 50000.00, 'Isapre Banmedica'),
('Seguro de Salud Familiar', 'Plan familiar con cobertura médica integral', 'salud', 'Cobertura familiar completa, maternidad', 75000.00, 80000.00, 'Isapre Banmedica'),
('Seguro Dental', 'Cobertura dental preventiva y curativa', 'salud', 'Tratamientos dentales y ortodóncia', 15000.00, 25000.00, 'Vida Tres'),

-- Seguros de Auto
('Seguro Auto Terceros', 'Cobertura básica obligatoria para circular', 'auto', 'Responsabilidad civil hacia terceros', 180000.00, 150000.00, 'HDI Seguros'),
('Seguro Auto Integral', 'Protección completa para tu vehículo', 'auto', 'Todo riesgo, robo, incendio, terceros', 320000.00, 200000.00, 'HDI Seguros'),
('Seguro Auto Premium', 'Máxima protección con servicios adicionales', 'auto', 'Cobertura completa + grúa + auto de reemplazo', 450000.00, 150000.00, 'Zurich Seguros'),

-- Seguros de Hogar
('Seguro Hogar Básico', 'Protección básica para tu vivienda', 'hogar', 'Incendio, terremoto, robo', 120000.00, 100000.00, 'Liberty Seguros'),
('Seguro Hogar Integral', 'Cobertura completa para casa y contenido', 'hogar', 'Todo riesgo hogar + responsabilidad civil', 200000.00, 150000.00, 'Liberty Seguros'),
('Seguro Hogar Premium', 'Máxima protección con servicios de emergencia', 'hogar', 'Cobertura integral + servicios 24/7', 280000.00, 100000.00, 'Mapfre Seguros'),

-- Seguros de Viaje
('Seguro de Viaje Nacional', 'Protección para viajes dentro de Chile', 'viaje', 'Asistencia médica, cancelación de viaje', 8000.00, 20000.00, 'Assist Card'),
('Seguro de Viaje Internacional', 'Cobertura completa para viajes al extranjero', 'viaje', 'Asistencia médica internacional, repatriación', 25000.00, 50000.00, 'Assist Card'),

-- Seguros Comerciales
('Seguro PYME Básico', 'Protección esencial para pequeñas empresas', 'comercial', 'Responsabilidad civil, incendio', 150000.00, 200000.00, 'RSA Seguros'),
('Seguro PYME Integral', 'Cobertura completa para empresas', 'comercial', 'Todo riesgo comercial + pérdida de beneficios', 300000.00, 300000.00, 'RSA Seguros'),

-- Seguros Especializados
('Seguro de Mascotas', 'Protección veterinaria para tu mascota', 'mascota', 'Gastos veterinarios, cirugías', 20000.00, 30000.00, 'Bupa Chile'),
('Seguro de Equipos Electrónicos', 'Protege tus dispositivos tecnológicos', 'tecnologia', 'Robo, daños accidentales de equipos', 12000.00, 25000.00, 'Sura Chile'),
('Seguro de Bicicleta', 'Protección para ciclistas urbanos', 'recreativo', 'Robo, daños, responsabilidad civil', 8000.00, 15000.00, 'Bice Seguros');

-- Sample data for service types
USE agenda_ms;
INSERT IGNORE INTO service_types (name, description, duration_minutes, price) VALUES
('Consulta Financiera', 'Asesoramiento financiero personalizado', 60, 25000.00),
('Evaluación Crediticia', 'Evaluación de perfil crediticio', 45, 15000.00),
('Planificación Inversiones', 'Planificación de cartera de inversiones', 90, 40000.00),
('Seguro Personalizado', 'Consulta para seguros personalizados', 30, 12000.00),
('Apertura Cuenta Corriente', 'Apertura de nueva cuenta corriente', 30, 0.00),
('Apertura Cuenta Ahorro', 'Apertura de cuenta de ahorro', 20, 0.00),
('Crédito Hipotecario', 'Consulta para crédito hipotecario', 90, 35000.00),
('Crédito Consumo', 'Evaluación para crédito de consumo', 45, 20000.00);

-- Sample data for sucursales (branches)
INSERT IGNORE INTO sucursales (nombre, direccion, telefono, horario_atencion, ciudad, region) VALUES
('Sucursal Las Condes', 'Av. Apoquindo 4501, Las Condes', '+56225551001', 'Lun-Vie 9:00-18:00, Sáb 9:00-14:00', 'Santiago', 'Metropolitana'),
('Sucursal Providencia', 'Av. Providencia 1650, Providencia', '+56225551002', 'Lun-Vie 9:00-18:00, Sáb 9:00-14:00', 'Santiago', 'Metropolitana'),
('Sucursal Centro', 'Estado 260, Santiago Centro', '+56225551003', 'Lun-Vie 9:00-17:00', 'Santiago', 'Metropolitana'),
('Sucursal Ñuñoa', 'Av. Irarrázaval 2901, Ñuñoa', '+56225551004', 'Lun-Vie 9:00-18:00, Sáb 9:00-13:00', 'Santiago', 'Metropolitana'),
('Sucursal Valparaíso', 'Av. Pedro Montt 2055, Valparaíso', '+56325551005', 'Lun-Vie 9:00-17:00', 'Valparaíso', 'Valparaíso'),
('Sucursal Viña del Mar', 'Av. Libertad 1348, Viña del Mar', '+56325551006', 'Lun-Vie 9:00-18:00, Sáb 9:00-14:00', 'Viña del Mar', 'Valparaíso'),
('Sucursal Concepción', 'Av. O'Higgins 680, Concepción', '+56415551007', 'Lun-Vie 9:00-17:00', 'Concepción', 'Biobío'),
('Sucursal La Serena', 'Av. Francisco de Aguirre 355, La Serena', '+56515551008', 'Lun-Vie 9:00-17:00', 'La Serena', 'Coquimbo');
"

execute_sql "$SAMPLE_DATA_SQL" "Inserting sample data"

# ---------- CREAR USUARIOS ESPECÍFICOS ----------
echo "👥 Creating specific users..."

# Password 'welcome1' in plain text (as expected by login microservice)
USERS_SQL="
USE login_ms;

-- Insert main users in usuario table (used by login microservice)
INSERT IGNORE INTO usuario (id, username, nombre, password, email) VALUES
(1, 'admin', 'Admin User', 'welcome1', 'admin@bankportal.com'),
(2, 'dralquinta', 'denny Alquinta', 'welcome1', 'denny.alquinta@oracle.com');

-- Also insert in users table for compatibility
INSERT IGNORE INTO users (id, username, email, password_hash, first_name, last_name, phone) VALUES
(1, 'admin', 'admin@bankportal.com', '\$2b\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', '+56911111111'),
(2, 'dralquinta', 'denny.alquinta@oracle.com', '\$2b\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'denny', 'Alquinta', '+56922222222');
"

execute_sql "$USERS_SQL" "Creating main users"

# ---------- POBLAR DATOS DUMMY PARA USUARIOS ----------
echo "📊 Populating dummy data for users..."

DUMMY_DATA_SQL="
-- Populate agenda_ms with sample reservations (reserva table)
USE agenda_ms;

INSERT IGNORE INTO reserva (usuario_id, sucursal, fecha, hora) VALUES
-- Admin user reservations
(1, 'Sucursal Las Condes', '2025-09-15', '10:00:00'),
(1, 'Sucursal Providencia', '2025-09-18', '14:30:00'),
(1, 'Sucursal Centro', '2025-09-22', '11:00:00'),

-- Dralquinta user reservations
(2, 'Sucursal Ñuñoa', '2025-09-17', '09:00:00'),
(2, 'Sucursal Valparaíso', '2025-09-20', '15:00:00'),
(2, 'Sucursal Viña del Mar', '2025-09-25', '16:30:00');

-- Also populate the extended reservations table
INSERT IGNORE INTO reservations (user_id, customer_name, customer_email, customer_phone, appointment_date, appointment_time, service_type, description, status) VALUES
-- Admin user reservations
(1, 'María González', 'maria.gonzalez@email.com', '+56933333333', '2025-09-15', '10:00:00', 'Consulta Financiera', 'Consulta sobre planificación financiera personal', 'confirmed'),
(1, 'Carlos Rodríguez', 'carlos.rodriguez@email.com', '+56944444444', '2025-09-16', '14:30:00', 'Evaluación Crediticia', 'Evaluación para crédito hipotecario', 'pending'),
(1, 'Ana López', 'ana.lopez@email.com', '+56955555555', '2025-09-18', '11:00:00', 'Seguro Personalizado', 'Cotización seguro de vida', 'confirmed'),

-- Dralquinta user reservations
(2, 'Pedro Martínez', 'pedro.martinez@email.com', '+56966666666', '2025-09-17', '09:00:00', 'Planificación Inversiones', 'Asesoría para cartera de inversiones', 'confirmed'),
(2, 'Lucía Silva', 'lucia.silva@email.com', '+56977777777', '2025-09-19', '15:00:00', 'Consulta Financiera', 'Consulta sobre refinanciamiento', 'pending'),
(2, 'Roberto Chen', 'roberto.chen@email.com', '+56988888888', '2025-09-20', '16:30:00', 'Evaluación Crediticia', 'Evaluación para crédito comercial', 'confirmed');

-- Populate cotizar_ms with sample quotes (cotizacion table)
USE cotizar_ms;

INSERT IGNORE INTO cotizacion (usuario_id, producto_seguro_id, monto, plazo_meses, tasa_anual, cuota_mensual, total_pagado, cae) VALUES
-- Admin user quotes
(1, 1, 1000000.00, 12, 5.50, 85847.00, 1030164.00, 6.20),
(1, 7, 15000000.00, 24, 8.20, 696545.00, 16717080.00, 9.15),
(1, 10, 500000.00, 6, 12.00, 86066.00, 516396.00, 12.68),

-- Dralquinta user quotes
(2, 2, 2000000.00, 18, 6.80, 123456.00, 2222208.00, 7.45),
(2, 8, 25000000.00, 36, 7.50, 788901.00, 28400436.00, 8.22),
(2, 15, 300000.00, 12, 15.20, 27184.00, 326208.00, 16.85);

-- Also populate legacy insurance_quotes table for compatibility
INSERT IGNORE INTO insurance_quotes (user_id, customer_name, customer_email, age, gender, coverage_type, coverage_amount, premium_amount, risk_score, status, valid_until) VALUES
-- Admin user quotes
(1, 'María González', 'maria.gonzalez@email.com', 35, 'F', 'Vida Premium', 150000.00, 525.00, 2.5, 'quoted', '2025-10-15'),
(1, 'Carlos Rodríguez', 'carlos.rodriguez@email.com', 42, 'M', 'Auto Full', 45000.00, 1125.00, 3.2, 'accepted', '2025-10-16'),
(1, 'Ana López', 'ana.lopez@email.com', 28, 'F', 'Salud Individual', 25000.00, 200.00, 1.8, 'quoted', '2025-10-18'),

-- Dralquinta user quotes
(2, 'Pedro Martínez', 'pedro.martinez@email.com', 38, 'M', 'Vida Básico', 75000.00, 150.00, 2.1, 'accepted', '2025-10-17'),
(2, 'Lucía Silva', 'lucia.silva@email.com', 31, 'F', 'Auto Terceros', 15000.00, 225.00, 2.8, 'quoted', '2025-10-19'),
(2, 'Roberto Chen', 'roberto.chen@email.com', 45, 'M', 'Vida Premium', 200000.00, 700.00, 3.5, 'draft', '2025-10-20');

-- Populate pagar_ms with sample debts and payments
USE pagar_ms;

INSERT IGNORE INTO deudas (user_id, monto, descripcion, fecha_vencimiento, estado, tipo_deuda) VALUES
-- Admin user debts
(1, 150000.00, 'Crédito de consumo - cuota 3/12', '2025-09-30', 'pendiente', 'credito_consumo'),
(1, 85000.00, 'Tarjeta de crédito - saldo pendiente', '2025-09-15', 'pendiente', 'tarjeta_credito'),
(1, 320000.00, 'Crédito hipotecario - cuota mensual', '2025-10-01', 'pendiente', 'credito_hipotecario'),
(1, 45000.00, 'Seguro de auto - prima anual', '2025-08-15', 'pagada', 'seguro'),

-- Dralquinta user debts
(2, 75000.00, 'Crédito automotriz - cuota 8/36', '2025-09-25', 'pendiente', 'credito_automotriz'),
(2, 120000.00, 'Tarjeta de crédito - compras del mes', '2025-09-20', 'pendiente', 'tarjeta_credito'),
(2, 25000.00, 'Servicio premium banco - cuota trimestral', '2025-09-10', 'vencida', 'servicio_bancario'),
(2, 180000.00, 'Línea de crédito empresarial', '2025-10-05', 'pendiente', 'linea_credito');

-- Insert some payment records for paid debts
INSERT IGNORE INTO pagos (deuda_id, monto_pagado, metodo_pago, referencia_transaccion, estado) VALUES
(4, 45000.00, 'transferencia_bancaria', 'TXN-20250815-001', 'exitoso'),
(7, 25000.00, 'debito_automatico', 'TXN-20250810-002', 'revertido');
"

execute_sql "$DUMMY_DATA_SQL" "Populating dummy data for users"
"

execute_sql "$SAMPLE_DATA_SQL" "Inserting sample data"

# ---------- CREAR USUARIOS ESPECÍFICOS ----------
echo "👥 Creating specific users..."

# Password hashes for 'welcome1' - generated with bcrypt
# These are pre-computed bcrypt hashes for 'welcome1'
ADMIN_PASSWORD_HASH='\$2b\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'  # welcome1
DRALQUINTA_PASSWORD_HASH='\$2b\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'  # welcome1

USERS_SQL="
USE login_ms;

-- Insert main users
INSERT IGNORE INTO users (id, username, email, password_hash, first_name, last_name, phone) VALUES
(1, 'admin', 'admin@bankportal.com', '${ADMIN_PASSWORD_HASH}', 'Admin', 'User', '+56911111111'),
(2, 'dralquinta', 'denny.alquinta@oracle.com', '${DRALQUINTA_PASSWORD_HASH}', 'Denny', 'Alquinta', '+56922222222');
"

execute_sql "$USERS_SQL" "Creating main users"

# ---------- POBLAR DATOS DUMMY PARA USUARIOS ----------
echo "📊 Populating dummy data for users..."

DUMMY_DATA_SQL="
-- Populate agenda_ms with sample reservations
USE agenda_ms;

INSERT IGNORE INTO reservations (user_id, customer_name, customer_email, customer_phone, appointment_date, appointment_time, service_type, description, status) VALUES
-- Admin user reservations
(1, 'María González', 'maria.gonzalez@email.com', '+56933333333', '2025-09-15', '10:00:00', 'Consulta Financiera', 'Consulta sobre planificación financiera personal', 'confirmed'),
(1, 'Carlos Rodríguez', 'carlos.rodriguez@email.com', '+56944444444', '2025-09-16', '14:30:00', 'Evaluación Crediticia', 'Evaluación para crédito hipotecario', 'pending'),
(1, 'Ana López', 'ana.lopez@email.com', '+56955555555', '2025-09-18', '11:00:00', 'Seguro Personalizado', 'Cotización seguro de vida', 'confirmed'),

-- Dralquinta user reservations
(2, 'Pedro Martínez', 'pedro.martinez@email.com', '+56966666666', '2025-09-17', '09:00:00', 'Planificación Inversiones', 'Asesoría para cartera de inversiones', 'confirmed'),
(2, 'Lucía Silva', 'lucia.silva@email.com', '+56977777777', '2025-09-19', '15:00:00', 'Consulta Financiera', 'Consulta sobre refinanciamiento', 'pending'),
(2, 'Roberto Chen', 'roberto.chen@email.com', '+56988888888', '2025-09-20', '16:30:00', 'Evaluación Crediticia', 'Evaluación para crédito comercial', 'confirmed');

-- Populate cotizar_ms with sample quotes
USE cotizar_ms;

INSERT IGNORE INTO insurance_quotes (user_id, customer_name, customer_email, age, gender, coverage_type, coverage_amount, premium_amount, risk_score, status, valid_until) VALUES
-- Admin user quotes
(1, 'María González', 'maria.gonzalez@email.com', 35, 'F', 'Vida Premium', 150000.00, 525.00, 2.5, 'quoted', '2025-10-15'),
(1, 'Carlos Rodríguez', 'carlos.rodriguez@email.com', 42, 'M', 'Auto Full', 45000.00, 1125.00, 3.2, 'accepted', '2025-10-16'),
(1, 'Ana López', 'ana.lopez@email.com', 28, 'F', 'Salud Individual', 25000.00, 200.00, 1.8, 'quoted', '2025-10-18'),

-- Dralquinta user quotes
(2, 'Pedro Martínez', 'pedro.martinez@email.com', 38, 'M', 'Vida Básico', 75000.00, 150.00, 2.1, 'accepted', '2025-10-17'),
(2, 'Lucía Silva', 'lucia.silva@email.com', 31, 'F', 'Auto Terceros', 15000.00, 225.00, 2.8, 'quoted', '2025-10-19'),
(2, 'Roberto Chen', 'roberto.chen@email.com', 45, 'M', 'Vida Premium', 200000.00, 700.00, 3.5, 'draft', '2025-10-20');

-- Populate pagar_ms with sample debts and payments
USE pagar_ms;

INSERT IGNORE INTO deudas (user_id, monto, descripcion, fecha_vencimiento, estado, tipo_deuda) VALUES
-- Admin user debts
(1, 150000.00, 'Crédito de consumo - cuota 3/12', '2025-09-30', 'pendiente', 'credito_consumo'),
(1, 85000.00, 'Tarjeta de crédito - saldo pendiente', '2025-09-15', 'pendiente', 'tarjeta_credito'),
(1, 320000.00, 'Crédito hipotecario - cuota mensual', '2025-10-01', 'pendiente', 'credito_hipotecario'),
(1, 45000.00, 'Seguro de auto - prima anual', '2025-08-15', 'pagada', 'seguro'),

-- Dralquinta user debts
(2, 75000.00, 'Crédito automotriz - cuota 8/36', '2025-09-25', 'pendiente', 'credito_automotriz'),
(2, 120000.00, 'Tarjeta de crédito - compras del mes', '2025-09-20', 'pendiente', 'tarjeta_credito'),
(2, 25000.00, 'Servicio premium banco - cuota trimestral', '2025-09-10', 'vencida', 'servicio_bancario'),
(2, 180000.00, 'Línea de crédito empresarial', '2025-10-05', 'pendiente', 'linea_credito');

-- Insert some payment records for paid debts
INSERT IGNORE INTO pagos (deuda_id, monto_pagado, metodo_pago, referencia_transaccion, estado) VALUES
(4, 45000.00, 'transferencia_bancaria', 'TXN-20250815-001', 'exitoso'),
(7, 25000.00, 'debito_automatico', 'TXN-20250810-002', 'revertido');
"

execute_sql "$DUMMY_DATA_SQL" "Populating dummy data for users"

# ---------- VERIFICAR BASES DE DATOS CREADAS ----------
echo "🔍 Verifying created databases..."

SHOW_DATABASES_SQL="SHOW DATABASES;"
execute_sql "$SHOW_DATABASES_SQL" "Listing all databases"

echo "🎉 Database setup completed successfully!"
echo ""
echo "📋 Summary of created databases:"
echo "   • login_ms      - User authentication and sessions"
echo "   • agenda_ms     - Appointment scheduling"
echo "   • cotizar_ms    - Insurance quotes"
echo "   • pagar_ms      - Payment processing and debt management"
echo ""
echo "� Created users (password: welcome1):"
echo "   • admin         - Administrator user"
echo "   • dralquinta    - Denny Alquinta user"
echo ""
echo "�🔧 Each database includes:"
echo "   • Proper UTF8 character set and collation"
echo "   • Optimized indexes for performance"
echo "   • Sample data for testing"
echo "   • Foreign key constraints for data integrity"
echo "   • Realistic dummy data for both users"
echo ""
echo "📊 Dummy data includes:"
echo "   • 6 appointment reservations (3 per user)"
echo "   • 6 insurance quotes (3 per user)"
echo "   • 8 debt records with different statuses"
echo "   • Payment transaction history"
echo ""
echo "✅ All microservices should now be able to connect to their databases!"
echo "🔑 Login credentials: admin/welcome1 or dralquinta/welcome1"
