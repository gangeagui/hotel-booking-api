-- Charset y engine
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- Usuarios y roles
CREATE TABLE roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid BINARY(16) UNIQUE NOT NULL,
    email VARCHAR(180) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    given_name VARCHAR(100),
    family_name VARCHAR(100),
    phone VARCHAR(30),
    image_url VARCHAR(500),
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    provider ENUM('LOCAL','GOOGLE') NOT NULL DEFAULT 'LOCAL',
    provider_sub VARCHAR(255), -- sub/subject de OAuth2 (Google)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_email (email),
    INDEX idx_users_username (username)
) ENGINE=InnoDB;

CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Hoteles y amenidades
CREATE TABLE hotels (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    email VARCHAR(180),
    phone VARCHAR(30),
    star_rating TINYINT,
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(120),
    state VARCHAR(120),
    country VARCHAR(120),
    postal_code VARCHAR(20),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE amenities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE hotel_amenities (
    hotel_id BIGINT NOT NULL,
    amenity_id BIGINT NOT NULL,
    PRIMARY KEY (hotel_id, amenity_id),
    CONSTRAINT fk_hotel_amenities_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (id) ON DELETE CASCADE,
    CONSTRAINT fk_hotel_amenities_amenity FOREIGN KEY (amenity_id) REFERENCES amenities (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tipos de habitación y habitaciones
CREATE TABLE room_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hotel_id BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    capacity_adults TINYINT NOT NULL DEFAULT 2,
    capacity_children TINYINT NOT NULL DEFAULT 0,
    base_price DECIMAL(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_room_types_hotel_code (hotel_id, code),
    CONSTRAINT fk_room_types_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE rooms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hotel_id BIGINT NOT NULL,
    room_type_id BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL,
    floor VARCHAR(20),
    status ENUM('AVAILABLE','MAINTENANCE','OUT_OF_ORDER') DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_rooms_hotel_code (hotel_id, code),
    INDEX idx_rooms_room_type (room_type_id),
    CONSTRAINT fk_rooms_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (id) ON DELETE CASCADE,
    CONSTRAINT fk_rooms_room_type FOREIGN KEY (room_type_id) REFERENCES room_types (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Reservas y líneas
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL, -- quien reserva
    hotel_id BIGINT NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    status ENUM('PENDING','CONFIRMED','CANCELLED','COMPLETED','EXPIRED') NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    notes VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_bookings_user (user_id),
    INDEX idx_bookings_hotel (hotel_id),
    INDEX idx_bookings_dates (check_in, check_out),
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE booking_rooms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,
    guests_adults TINYINT NOT NULL DEFAULT 1,
    guests_children TINYINT NOT NULL DEFAULT 0,
    price_per_night DECIMAL(12,2) NOT NULL,
    nights INT NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_booking_room (booking_id, room_id),
    CONSTRAINT fk_booking_rooms_booking FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_rooms_room FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Pagos (PayPal)
CREATE TABLE payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    provider ENUM('PAYPAL') NOT NULL DEFAULT 'PAYPAL',
    provider_ref VARCHAR(255), -- paymentId / orderId / captureId
    status ENUM('CREATED','AUTHORIZED','COMPLETED','CANCELLED','FAILED','REFUNDED') NOT NULL DEFAULT 'CREATED',
    amount DECIMAL(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_payments_booking (booking_id),
    UNIQUE KEY uq_payments_provider_ref (provider, provider_ref),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payment_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    event_type VARCHAR(100) NOT NULL, -- e.g. PAYMENT.CAPTURE.COMPLETED
    payload JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payment_events_payment (payment_id),
    CONSTRAINT fk_payment_events_payment FOREIGN KEY (payment_id) REFERENCES payments (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Outbox de correos (para confiabilidad)
CREATE TABLE email_outbox (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient VARCHAR(180) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    template VARCHAR(120) NOT NULL, -- p.ej. booking_confirmation
    payload JSON, -- datos para la plantilla
    status ENUM('PENDING','SENT','FAILED') NOT NULL DEFAULT 'PENDING',
    error_message VARCHAR(500),
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email_outbox_status (status)
) ENGINE=InnoDB;

-- Semillas mínimas
INSERT INTO roles (name, description) VALUES
('ROLE_ADMIN', 'Administrator'),
('ROLE_MANAGER', 'Hotel manager'),
('ROLE_USER', 'Regular customer');