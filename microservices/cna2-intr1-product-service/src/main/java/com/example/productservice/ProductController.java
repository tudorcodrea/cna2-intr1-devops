package com.example.productservice;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/products")
public class ProductController {

    @Autowired
    private SnsService snsService;

    @GetMapping(path = "/health", produces = "application/json")
    public String health() {
        return "OK";
    }

    @PostMapping(path = "/prod", consumes = "application/json", produces = "application/json")
    public String createProduct(@RequestBody Product product) {
        Product newProduct = new Product(product.getName(), product.getDescription());
        snsService.publishProductEvent(newProduct);
        return "Product creation event published for " + newProduct.getName();
    }
}
