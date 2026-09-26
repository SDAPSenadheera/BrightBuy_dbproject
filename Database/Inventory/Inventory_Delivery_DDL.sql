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
    product_id INT, 
    warehouse_id INT,
    variant_name VARCHAR(100),
    colour VARCHAR(50),
    memory_size VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id) -- Links to Mihisara's domain
);

-- Delivery Table
CREATE TABLE delivery (
    delivery_id INT PRIMARY KEY,
    order_id INT, 
    city_id INT,
    delivery_mode VARCHAR(50),
    est_delivery_date DATE,
    delivery_status VARCHAR(50),
    FOREIGN KEY (city_id) REFERENCES city(city_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) -- Links to Adeesha's domain
);


--Run Mihisara's product table and Adeesha's orders table scripts before running this sql file
--to prevent foreign key errors.