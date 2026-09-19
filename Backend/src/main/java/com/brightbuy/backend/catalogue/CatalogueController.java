package com.brightbuy.backend.catalogue;

import org.springframework.http.MediaType;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import tools.jackson.databind.JsonNode;

@RestController
@RequestMapping(value = "/api/catalogue", produces = MediaType.APPLICATION_JSON_VALUE)
public class CatalogueController {
    private final CatalogueService service;

    public CatalogueController(CatalogueService service) { this.service = service; }

    @GetMapping("/products")
    public JsonNode search(@RequestParam MultiValueMap<String, String> parameters) {
        return service.search(CatalogueSearch.from(parameters));
    }

    @GetMapping("/products/{productId}")
    public JsonNode product(@PathVariable String productId) {
        return service.product(CatalogueSearch.positiveInt(productId, "productId", Integer.MAX_VALUE));
    }

    @GetMapping("/categories")
    public JsonNode categories() { return service.categories(); }
}
