# BrightBuy Management Reporing Database Module

## Owner

Adeesha Senadheera

## Purpose

Implements the database layer for BrightBuy's 5 mandatory management reports,
 - Quarterly sales report
 - Top selling products report
 - Category-wise total number of orders
 - Delivery time estimatess for upcoming orders
 - Customer-wise order summary with payment status

## Tables Owned

 - `sales_summary`
 - `report_access_log`

## Dependencies on other modules

         Table            |     Owned by     |                    Used by
--------------------------------------------------------------------------------------------------
        variant           |    Catalogue     |       sales_summary, Top selling products
        product           |    Catalogue     |               Top selling product
 product_category,category|    Catalogue     |       Categor-wise total number of orders
        employee          |                  |                report_access_log
    orders, order_items   |                  |  sales_summary,Category-wise total number of orders
        customer          |                  |    Customer-wise order summary with payment status
        payment           |                  |    Customer-wise order summary with payment status
     delivery, city       |                  |      Delivery time estimatess for upcoming orders


## Refresh schedule

 - sp_refresh_sales_summary is not called automatically yet. Options:
    - A MySQL EVENT scheduled to run daily (requires SET GLOBAL event_scheduler = ON; on the server)
    - A manual/cron-triggered call from the application or an ops script.

 - Status: not yet decided/implemented. Until then, sales_summary must be refreshed manually for testing.

## Assumptions
 - sales_summary.order_count counts distinct orders per variant/day, not order lines.
 - Category-wise order counts and delivery estimates read live from orders,order_item,delivery rather than from sales_summary, since they need current status, not a historical rollup.
 - sp_customer_order_summary includes all orders regardless of payment status.
 - Cancelled orders are excluded from sales_summary and category order counts matching the reports' intent to reflect real sales activity.