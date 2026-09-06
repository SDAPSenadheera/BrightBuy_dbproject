-- creating sales_summary table
CREATE TABLE sales_summary(
	summary_id  INT PRIMARY KEY AUTO_INCREMENT,
	variant_id  INT NOT NULL,
	summary_date DATE NOT NULL,
	units_sold  INT NOT NULL DEFAULT 0,
	total_revenue DECIMAL(12,2) NOT NULL DEFAULT 0,
	order_count INT NOT NULL DEFAULT 0,
	FOREIGN KEY(VARIANT_ID) REFERENCES variant(variant_id),
	UNIQUE KEY uq_variant_date (variant_id, summary_date)
);

-- creating report_access_log table

CREATE TABLE report_access_log(
	log_id  INT PRIMARY KEY AUTO_INCREMENT,
	employee_id INT NOT NULL,
	report_name VARCHAR(100) NOT NULL,
	accessed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(employee_id) REFERENCES employee(employee_id) 
	
);

-- create index for summary_date

CREATE INDEX idx_summary_date ON sales_summary(summary_date);

-- create index for employee id

CREATE INDEX idx_accesslog_employee ON report_access_log(employee_id);




























