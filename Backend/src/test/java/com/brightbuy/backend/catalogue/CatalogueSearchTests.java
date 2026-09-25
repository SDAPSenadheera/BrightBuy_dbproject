package com.brightbuy.backend.catalogue;

import static org.assertj.core.api.Assertions.*;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.util.LinkedMultiValueMap;

class CatalogueSearchTests {
    @Test
    void defaultsMatchProcedureContract() {
        assertThat(CatalogueSearch.from(new LinkedMultiValueMap<>()))
                .isEqualTo(new CatalogueSearch(null, null, null, null, false, "name_asc", 1, 12));
    }

    @Test
    void bindsEveryFilterWithExactDecimals() {
        var parameters = new LinkedMultiValueMap<String, String>();
        parameters.add("keyword", "  iPhone  ");
        parameters.add("categoryId", "4");
        parameters.add("minPrice", "100.00");
        parameters.add("maxPrice", "99999999.99");
        parameters.add("inStockOnly", "true");
        parameters.add("sort", " PRICE_ASC ");
        parameters.add("page", "1000000");
        parameters.add("pageSize", "100");
        assertThat(CatalogueSearch.from(parameters)).isEqualTo(new CatalogueSearch("iPhone", 4,
                new BigDecimal("100.00"), new BigDecimal("99999999.99"), true, "price_asc", 1000000, 100));
    }

    @ParameterizedTest
    @CsvSource({
        "page,0", "page,-1", "page,1.5", "page,1000001", "page,999999999999999999999",
        "pageSize,101", "pageSize,0", "pageSize,hello", "categoryId,0", "categoryId,2147483648",
        "minPrice,-1", "maxPrice,-1", "minPrice,1.001", "maxPrice,100000000",
        "minPrice,1e2", "minPrice,NaN", "inStockOnly,1", "inStockOnly,yes", "sort,random",
        "typoParameter,123", "categoryId,''", "minPrice,''", "page,''"
    })
    void invalidParametersRejected(String field, String value) {
        var parameters = new LinkedMultiValueMap<String, String>();
        parameters.add(field, value);
        assertThatThrownBy(() -> CatalogueSearch.from(parameters)).isInstanceOf(CatalogueException.class);
    }

    @Test
    void rejectsReversedRange() {
        var parameters = new LinkedMultiValueMap<String, String>();
        parameters.add("minPrice", "100");
        parameters.add("maxPrice", "10");
        assertThatThrownBy(() -> CatalogueSearch.from(parameters)).isInstanceOf(CatalogueException.class);
    }

    @Test
    void unicodeLimitCountsCharactersNotUtf16Units() {
        var parameters = new LinkedMultiValueMap<String, String>();
        parameters.add("keyword", "🙂".repeat(255));
        assertThat(CatalogueSearch.from(parameters).keyword()).isEqualTo("🙂".repeat(255));
        parameters.set("keyword", "🙂".repeat(256));
        assertThatThrownBy(() -> CatalogueSearch.from(parameters)).isInstanceOf(CatalogueException.class);
    }

    @Test
    void blankKeywordAndSortUseDefaults() {
        var parameters = new LinkedMultiValueMap<String, String>();
        parameters.add("keyword", "  ");
        parameters.add("sort", "  ");
        assertThat(CatalogueSearch.from(parameters).keyword()).isNull();
        assertThat(CatalogueSearch.from(parameters).sort()).isEqualTo("name_asc");
    }
}
