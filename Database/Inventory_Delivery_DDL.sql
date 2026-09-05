-- City Table
CREATE TABLE city (
    city_id INT PRIMARY KEY,
    name VARCHAR(100),
    is_main_city BOOLEAN
);

-- Warehouse Table
CREATE TABLE warehouse (
    warehouse_id INT PRIMARY KEY,
    name VARCHAR(100),
    location VARCHAR(255)
);

-- Variant Table (Includes Catalog details + Inventory details)
CREATE TABLE variant (
    variant_id INT PRIMARY KEY,
    product_id INT, -- FK to Product table(mihisara part)
    warehouse_id INT,
    variant_name VARCHAR(100),
    colour VARCHAR(50),
    memory_size VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT,
    FOREIGN KEY (warehouse_id) REFERENCES WAREHOUSE(warehouse_id)
);

-- Delivery Table
CREATE TABLE  delivery (
    delivery_id INT PRIMARY KEY,
    order_id INT, -- FK to Orders table (Adeesha part)
    city_id INT,
    delivery_mode VARCHAR(50),
    est_delivery_date DATE,
    delivery_status VARCHAR(50),
    FOREIGN KEY (city_id) REFERENCES CITY(city_id)
);