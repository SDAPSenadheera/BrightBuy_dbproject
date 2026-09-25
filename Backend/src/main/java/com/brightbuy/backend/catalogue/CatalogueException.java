package com.brightbuy.backend.catalogue;

import org.springframework.http.HttpStatus;

public class CatalogueException extends RuntimeException {
    private final HttpStatus status;
    private final String code;

    public CatalogueException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public CatalogueException(HttpStatus status, String code, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
        this.code = code;
    }

    public HttpStatus status() { return status; }
    public String code() { return code; }

    static CatalogueException invalid(String message) {
        return new CatalogueException(HttpStatus.BAD_REQUEST, "INVALID_PARAMETER", message);
    }
}
