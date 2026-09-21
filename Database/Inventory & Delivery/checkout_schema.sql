--- Orders Table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,--used auto increment to increment value automaticaly
    customer_id INT ,
    order_date DATE,
    order_status VARCHAR(50),
    total_amount Decimal(10,2)
    FOREIGN KEY(customer_id) REFERENCES Customer(customer_id)
);

--Order_Item Table
CREATE TABLE order_Item(
    order_id INT,
    varient_id INT,
    quantity INT,
    unit_price Decimal(10,2),
    PRIMARY KEY (order_id, varient_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE RESTRICT, -- added ON DELETE to restrict deletion of orders if they have associated order items
    FOREIGN KEY (varient_id) REFERENCES Variant(varient_id) ON DELETE RESTRICT
);

-- Delivery Table
CREATE TABLE  delivery (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY, -- added Auto increment to automatically generate unique delivery IDs
    order_id INT, 
    city_id INT,
    delivery_mode VARCHAR(50),
    est_delivery_date DATE,
    delivery_status VARCHAR(50),
    FOREIGN KEY (city_id) REFERENCES city(city_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

--payment Table
CREATE TABLE payment(
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT 
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    amount DECIMAL(10,2),
    payment_date DATE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
