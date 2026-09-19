-- =========================================================
-- BrightBuy Catalogue Indexes
-- Author: Kavindu Mihisara
-- =========================================================

USE brightbuy;

CREATE INDEX idx_product_name
    ON product(name);

CREATE INDEX idx_product_active_name
    ON product(is_active, name);

CREATE FULLTEXT INDEX idx_product_search
    ON product(name, description);
