# Project work log
# S.D.A.P. Senadheera
# Role : 

## 2026.09.16

## Completed
 -- Management reporting 
   - Created the required tables for the Management Reporting section.
   - Added sample/summary data insertion logic for the sales_summary table.
   - Added report_access_log insertion logic.
   - Created the following reporting queries:
        - Quarterly Sales Report
        - Top Selling Products Report
        - Category-wise Total Number of Orders
        - Delivery Time Estimates for Upcoming Orders
        - Customer-wise Order Summary with Payment Status


## NEXT
- Create API endpoints for each report.
- Implement query parameters to extract `startDate` and `endDate` filters from the request.
- Connect the Express routes to execute the completed MySQL queries.
- Format and send the database results back to the client as JSON arrays.

## Catalogue & Search — Kavindu Mihisara

### Completed
- Created catalogue tables, indexes, constraints, and variant integration.
- Added sample data covering 40 products, 10 categories, and 48 variants.
- Implemented SQL procedures and backend APIs for product search, filtering, sorting, pagination, categories, and product details.
- Built the catalogue Home/Browse UI with loading, error, empty-result, and stock states.
- Added frontend product-detail API types, response validation, and error handling.
- Latest frontend checks: all 100 tests, lint, and both builds passed.

### Remaining
- Product Detail page and variant-selection UI.
- Cart handoff coordination with the checkout owner.
- Integration into shared frontend navigation.
- Final end-to-end testing and verification on the team’s MySQL 8 setup.

### Integration Notes
- Backend routes: `/api/catalogue/products`, `/api/catalogue/products/{id}`, `/api/catalogue/categories`.
- Frontend currently uses the separate `/catalogue.html` entry.
- Catalogue reads stock; inventory and checkout own stock updates.
