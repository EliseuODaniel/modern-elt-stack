CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(32),
    country VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS erp.products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(64) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(64) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS erp.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES erp.customers(customer_id),
    order_status VARCHAR(32) NOT NULL,
    order_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS erp.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES erp.orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES erp.products(product_id),
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD'
);

CREATE TABLE IF NOT EXISTS erp.payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES erp.orders(order_id) ON DELETE CASCADE,
    payment_method VARCHAR(32) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    payment_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(32) NOT NULL
);

INSERT INTO erp.customers (customer_name, email, phone, country, created_at) VALUES
    ('Lena Rivers', 'lena.rivers@example.com', '+1-202-555-0101', 'USA', '2023-01-05 10:15:00'),
    ('Kai Nakamura', 'kai.nakamura@example.com', '+81-3-5555-0102', 'Japan', '2023-02-18 08:45:00'),
    ('Isabel Martins', 'isabel.martins@example.com', '+55-11-99999-0103', 'Brazil', '2023-03-22 12:30:00'),
    ('Noah Singh', 'noah.singh@example.com', '+91-22-5555-0104', 'India', '2023-04-10 09:00:00'),
    ('Sofia Rossi', 'sofia.rossi@example.com', '+39-02-5555-0105', 'Italy', '2023-04-15 15:10:00'),
    ('Emma Johansson', 'emma.johansson@example.com', '+46-8-5555-0106', 'Sweden', '2023-05-05 11:50:00'),
    ('Mason Wright', 'mason.wright@example.com', '+1-415-555-0107', 'USA', '2023-05-28 17:15:00'),
    ('Julia Costa', 'julia.costa@example.com', '+351-21-555-0108', 'Portugal', '2023-06-02 13:45:00'),
    ('Omar Haddad', 'omar.haddad@example.com', '+971-4-555-0109', 'UAE', '2023-06-11 07:25:00'),
    ('Mila Petrova', 'mila.petrova@example.com', '+359-2-555-0110', 'Bulgaria', '2023-06-20 20:10:00');

INSERT INTO erp.products (sku, product_name, category, price, currency, created_at) VALUES
    ('SKU-1001', 'Smart Sensor A1', 'IoT', 129.99, 'USD', '2023-01-01 00:00:00'),
    ('SKU-1002', 'Smart Sensor A2', 'IoT', 149.99, 'USD', '2023-01-01 00:00:00'),
    ('SKU-2001', 'Gateway Edge G1', 'Infrastructure', 499.00, 'USD', '2023-01-01 00:00:00'),
    ('SKU-2002', 'Gateway Edge G2', 'Infrastructure', 699.00, 'USD', '2023-01-01 00:00:00'),
    ('SKU-3001', 'Analytics Suite Basic', 'Software', 999.00, 'USD', '2023-01-01 00:00:00'),
    ('SKU-3002', 'Analytics Suite Pro', 'Software', 1999.00, 'USD', '2023-01-01 00:00:00'),
    ('SKU-4001', 'Maintenance Pack Lite', 'Services', 249.00, 'USD', '2023-01-01 00:00:00'),
    ('SKU-4002', 'Maintenance Pack Plus', 'Services', 449.00, 'USD', '2023-01-01 00:00:00');

INSERT INTO erp.orders (customer_id, order_status, order_ts, updated_ts, total_amount) VALUES
    (1, 'COMPLETED', '2023-07-01 10:00:00', '2023-07-01 10:05:00', 779.97),
    (2, 'COMPLETED', '2023-07-02 14:00:00', '2023-07-02 14:10:00', 2148.00),
    (3, 'PENDING',   '2023-07-03 09:30:00', '2023-07-03 09:45:00', 129.99),
    (4, 'COMPLETED', '2023-07-04 11:15:00', '2023-07-04 11:30:00', 2698.00),
    (5, 'CANCELLED', '2023-07-05 16:45:00', '2023-07-05 17:00:00', 499.00),
    (6, 'COMPLETED', '2023-07-06 08:20:00', '2023-07-06 08:25:00', 3498.00),
    (7, 'COMPLETED', '2023-07-07 13:05:00', '2023-07-07 13:10:00', 578.99),
    (8, 'COMPLETED', '2023-07-08 19:40:00', '2023-07-08 19:50:00', 2448.00),
    (9, 'PENDING',   '2023-07-09 07:55:00', '2023-07-09 08:05:00', 449.00),
    (10, 'COMPLETED','2023-07-10 21:15:00', '2023-07-10 21:30:00', 2148.00);

INSERT INTO erp.order_items (order_id, product_id, quantity, unit_price, currency) VALUES
    (1, 1, 3, 129.99, 'USD'),
    (2, 3, 2, 499.00, 'USD'),
    (2, 8, 2, 449.00, 'USD'),
    (3, 1, 1, 129.99, 'USD'),
    (4, 4, 2, 699.00, 'USD'),
    (4, 6, 1, 1999.00, 'USD'),
    (5, 3, 1, 499.00, 'USD'),
    (6, 6, 1, 1999.00, 'USD'),
    (6, 4, 1, 699.00, 'USD'),
    (6, 2, 2, 149.99, 'USD'),
    (7, 1, 2, 129.99, 'USD'),
    (7, 7, 1, 249.00, 'USD'),
    (8, 5, 1, 999.00, 'USD'),
    (8, 8, 2, 449.00, 'USD'),
    (9, 7, 1, 249.00, 'USD'),
    (10, 3, 2, 499.00, 'USD'),
    (10, 8, 2, 449.00, 'USD');

INSERT INTO erp.payments (order_id, payment_method, amount, payment_ts, status) VALUES
    (1, 'CREDIT_CARD', 779.97, '2023-07-01 10:02:00', 'CAPTURED'),
    (2, 'BANK_TRANSFER', 2148.00, '2023-07-02 14:12:00', 'CAPTURED'),
    (3, 'CREDIT_CARD', 129.99, '2023-07-03 09:50:00', 'PENDING'),
    (4, 'CREDIT_CARD', 2698.00, '2023-07-04 11:32:00', 'CAPTURED'),
    (5, 'PAYPAL', 499.00, '2023-07-05 17:05:00', 'REFUNDED'),
    (6, 'BANK_TRANSFER', 3498.00, '2023-07-06 08:27:00', 'CAPTURED'),
    (7, 'CREDIT_CARD', 578.99, '2023-07-07 13:15:00', 'CAPTURED'),
    (8, 'CREDIT_CARD', 2448.00, '2023-07-08 19:55:00', 'CAPTURED'),
    (9, 'PAYPAL', 449.00, '2023-07-09 08:07:00', 'PENDING'),
    (10, 'BANK_TRANSFER', 2148.00, '2023-07-10 21:35:00', 'CAPTURED');
