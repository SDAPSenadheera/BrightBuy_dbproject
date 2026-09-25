package com.brightbuy.backend.catalogue;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = CatalogueController.class)
public class CatalogueErrorHandler {
    private static final Logger log = LoggerFactory.getLogger(CatalogueErrorHandler.class);

    @ExceptionHandler(CatalogueException.class)
    public ProblemDetail handle(CatalogueException exception) {
        if (exception.status().is5xxServerError()) log.error("Catalogue operation failed", exception);
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(exception.status(), exception.getMessage());
        problem.setProperty("code", exception.code());
        return problem;
    }
}
