package com.brightbuy.backend.catalogue;

import static org.assertj.core.api.Assertions.*;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** Opt-in end-to-end tests; requires the isolated milestone-3 SQL fixtures. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("catalogue")
@EnabledIfEnvironmentVariable(named = "BRIGHTBUY_RUN_DB_TESTS", matches = "true")
class CatalogueMySqlTests {
    @LocalServerPort int port;
    @Autowired JsonMapper mapper;
    private final HttpClient client = HttpClient.newHttpClient();

    private HttpResponse<String> get(String path) throws Exception {
        return client.send(HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + path))
                .header("Accept", "application/json").GET().build(), HttpResponse.BodyHandlers.ofString());
    }

    private JsonNode ok(String path) throws Exception {
        var response = get(path);
        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        return mapper.readTree(response.body());
    }

    @Test
    void searchCallsMysqlProcedure() throws Exception {
        JsonNode result = ok("/api/catalogue/products");
        assertThat(result.get("total_products").asInt()).isEqualTo(39);
        assertThat(result.get("items").size()).isEqualTo(12);
        assertThat(result.get("total_pages").asInt()).isEqualTo(4);
    }

    @Test
    void categoriesAndDetailComeFromMysql() throws Exception {
        assertThat(ok("/api/catalogue/categories").get("items").size()).isEqualTo(10);
        JsonNode product = ok("/api/catalogue/products/1");
        assertThat(product.get("variants").size()).isEqualTo(3);
        assertThat(product.get("image_url").isNull()).isTrue();
    }

    @Test
    void combinedVariantFilterAndPagination() throws Exception {
        JsonNode matches = ok("/api/catalogue/products?keyword=BB-PHONE-NOVA&categoryId=4&minPrice=400&maxPrice=500&inStockOnly=true&sort=price_asc");
        assertThat(matches.get("total_products").asInt()).isEqualTo(1);
        assertThat(matches.get("items").get(0).get("min_price").decimalValue()).isEqualByComparingTo("449.00");
        assertThat(ok("/api/catalogue/products?page=4").get("items").size()).isEqualTo(3);
        assertThat(ok("/api/catalogue/products?page=99").get("items").isEmpty()).isTrue();
    }

    @Test
    void errorsAndVisibilityUseHttpContract() throws Exception {
        assertThat(get("/api/catalogue/products/40").statusCode()).isEqualTo(404);
        assertThat(get("/api/catalogue/products/99999").statusCode()).isEqualTo(404);
        assertThat(get("/api/catalogue/products?pageSize=101").statusCode()).isEqualTo(400);
        assertThat(get("/api/catalogue/products?minPrice=1.001").statusCode()).isEqualTo(400);
        assertThat(ok("/api/catalogue/products?keyword=zzzzzznoresult").get("items").isEmpty()).isTrue();
    }
}
