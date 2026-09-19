package com.brightbuy.backend.catalogue;

import java.math.BigDecimal;
import java.util.Locale;
import java.util.Set;
import org.springframework.util.MultiValueMap;

/** Validated values matching the SQL procedure's parameter contract. */
public record CatalogueSearch(
        String keyword, Integer categoryId, BigDecimal minPrice, BigDecimal maxPrice,
        boolean inStockOnly, String sort, int page, int pageSize) {

    private static final Set<String> PARAMETERS = Set.of(
            "keyword", "categoryId", "minPrice", "maxPrice", "inStockOnly", "sort", "page", "pageSize");
    private static final Set<String> SORTS = Set.of("name_asc", "name_desc", "price_asc", "price_desc", "newest");

    public static CatalogueSearch from(MultiValueMap<String, String> parameters) {
        parameters.forEach((key, values) -> {
            if (!PARAMETERS.contains(key)) throw CatalogueException.invalid("Unsupported query parameter.");
            if (values.size() != 1) throw CatalogueException.invalid("Query parameters must not be repeated.");
        });

        String keyword = parameters.getFirst("keyword");
        if (keyword != null) {
            keyword = keyword.trim();
            if (keyword.codePointCount(0, keyword.length()) > 255)
                throw CatalogueException.invalid("keyword must not exceed 255 characters.");
            if (keyword.isEmpty()) keyword = null;
        }
        Integer category = parameters.containsKey("categoryId")
                ? positiveInt(parameters.getFirst("categoryId"), "categoryId", Integer.MAX_VALUE) : null;
        BigDecimal min = price(parameters.getFirst("minPrice"), "minPrice");
        BigDecimal max = price(parameters.getFirst("maxPrice"), "maxPrice");
        if (min != null && max != null && min.compareTo(max) > 0)
            throw CatalogueException.invalid("minPrice must not exceed maxPrice.");

        String stock = parameters.getFirst("inStockOnly");
        if (stock == null) stock = "false";
        if (!stock.equals("true") && !stock.equals("false"))
            throw CatalogueException.invalid("inStockOnly must be true or false.");
        String sort = parameters.getFirst("sort");
        sort = sort == null || sort.isBlank() ? "name_asc" : sort.trim().toLowerCase(Locale.ROOT);
        if (!SORTS.contains(sort)) throw CatalogueException.invalid("Unsupported catalogue sort.");
        int page = parameters.containsKey("page") ? positiveInt(parameters.getFirst("page"), "page", 1_000_000) : 1;
        int size = parameters.containsKey("pageSize") ? positiveInt(parameters.getFirst("pageSize"), "pageSize", 100) : 12;
        return new CatalogueSearch(keyword, category, min, max, Boolean.parseBoolean(stock), sort, page, size);
    }

    static int positiveInt(String value, String field, int maximum) {
        if (value == null || !value.matches("[0-9]{1,10}"))
            throw CatalogueException.invalid(field + " must be a positive integer.");
        long number = Long.parseLong(value);
        if (number < 1 || number > maximum)
            throw CatalogueException.invalid(field + " must be between 1 and " + maximum + ".");
        return (int) number;
    }

    private static BigDecimal price(String value, String field) {
        if (value == null) return null;
        // Reject excess precision and exponential notation BEFORE MySQL can round/coerce it.
        if (!value.matches("[0-9]{1,8}(\\.[0-9]{1,2})?"))
            throw CatalogueException.invalid(field + " must be between 0 and 99999999.99 with at most two decimals.");
        return new BigDecimal(value);
    }
}
