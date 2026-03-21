# ================================================================
# MCart Cart Service - File Generator
# Run from: D:\ECOM Case Study\mcart-cart-service\
# Command: powershell -ExecutionPolicy Bypass -File create-files.ps1
# ================================================================

Write-Host "Creating folders..." -ForegroundColor Cyan

# Create ALL folders first
New-Item -ItemType Directory -Force -Path "src\main\java\com\mcart\cartservice" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\java\com\mcart\cartservice\controller" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\java\com\mcart\cartservice\model" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\java\com\mcart\cartservice\service" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\java\com\mcart\cartservice\repository" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\resources" | Out-Null

Write-Host "Folders created. Creating Java files..." -ForegroundColor Cyan

# CartServiceApplication.java
Set-Content -Path "src\main\java\com\mcart\cartservice\CartServiceApplication.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CartServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(CartServiceApplication.class, args);
    }
}
"@

# Cart.java
Set-Content -Path "src\main\java\com\mcart\cartservice\model\Cart.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice.model;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "carts")
public class Cart {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "user_id", unique = true, nullable = false)
    private String userId;

    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<CartItem> items = new ArrayList<>();

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at")
    private Instant updatedAt = Instant.now();

    public Cart() {}
    public Cart(String userId) { this.userId = userId; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public List<CartItem> getItems() { return items; }
    public void setItems(List<CartItem> items) { this.items = items; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public double getTotal() {
        return items.stream().mapToDouble(i -> i.getPrice() * i.getQty()).sum();
    }
}
"@

# CartItem.java
Set-Content -Path "src\main\java\com\mcart\cartservice\model\CartItem.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "cart_items")
public class CartItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne
    @JoinColumn(name = "cart_id", nullable = false)
    @JsonIgnore
    private Cart cart;

    @Column(name = "product_id", nullable = false)
    private String productId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private double price;

    @Column(nullable = false)
    private int qty;

    public CartItem() {}

    public CartItem(Cart cart, String productId, String name, double price, int qty) {
        this.cart = cart;
        this.productId = productId;
        this.name = name;
        this.price = price;
        this.qty = qty;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public Cart getCart() { return cart; }
    public void setCart(Cart cart) { this.cart = cart; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
    public int getQty() { return qty; }
    public void setQty(int qty) { this.qty = qty; }
}
"@

# CartRepository.java
Set-Content -Path "src\main\java\com\mcart\cartservice\repository\CartRepository.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice.repository;

import com.mcart.cartservice.model.Cart;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CartRepository extends JpaRepository<Cart, String> {
    Optional<Cart> findByUserId(String userId);
}
"@

# CartItemRepository.java
Set-Content -Path "src\main\java\com\mcart\cartservice\repository\CartItemRepository.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice.repository;

import com.mcart.cartservice.model.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CartItemRepository extends JpaRepository<CartItem, String> {}
"@

# CartService.java
Set-Content -Path "src\main\java\com\mcart\cartservice\service\CartService.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice.service;

import com.mcart.cartservice.model.Cart;
import com.mcart.cartservice.model.CartItem;
import com.mcart.cartservice.repository.CartRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;

@Service
@Transactional
public class CartService {

    private final CartRepository cartRepository;

    public CartService(CartRepository cartRepository) {
        this.cartRepository = cartRepository;
    }

    public Cart getOrCreateCart(String userId) {
        return cartRepository.findByUserId(userId)
            .orElseGet(() -> cartRepository.save(new Cart(userId)));
    }

    public Cart addItem(String userId, String productId, String name, double price, int qty) {
        Cart cart = getOrCreateCart(userId);
        cart.getItems().stream()
            .filter(i -> i.getProductId().equals(productId))
            .findFirst()
            .ifPresentOrElse(
                existing -> existing.setQty(existing.getQty() + qty),
                () -> cart.getItems().add(new CartItem(cart, productId, name, price, qty))
            );
        cart.setUpdatedAt(Instant.now());
        return cartRepository.save(cart);
    }

    public Cart updateQty(String userId, String productId, int qty) {
        Cart cart = getOrCreateCart(userId);
        if (qty <= 0) return removeItem(userId, productId);
        cart.getItems().stream()
            .filter(i -> i.getProductId().equals(productId))
            .findFirst()
            .ifPresent(i -> i.setQty(qty));
        cart.setUpdatedAt(Instant.now());
        return cartRepository.save(cart);
    }

    public Cart removeItem(String userId, String productId) {
        Cart cart = getOrCreateCart(userId);
        cart.getItems().removeIf(i -> i.getProductId().equals(productId));
        cart.setUpdatedAt(Instant.now());
        return cartRepository.save(cart);
    }

    public void clearCart(String userId) {
        cartRepository.findByUserId(userId).ifPresent(cart -> {
            cart.getItems().clear();
            cartRepository.save(cart);
        });
    }
}
"@

# CartController.java
Set-Content -Path "src\main\java\com\mcart\cartservice\controller\CartController.java" -Encoding UTF8 -Value @"
package com.mcart.cartservice.controller;

import com.mcart.cartservice.model.Cart;
import com.mcart.cartservice.service.CartService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/cart")
@CrossOrigin(origins = "*")
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Cart Service OK");
    }

    @GetMapping("/{userId}")
    public ResponseEntity<Cart> getCart(@PathVariable String userId) {
        return ResponseEntity.ok(cartService.getOrCreateCart(userId));
    }

    @PostMapping("/{userId}/items")
    public ResponseEntity<Cart> addItem(@PathVariable String userId,
                                        @RequestBody Map<String, Object> body) {
        String productId = (String) body.get("productId");
        String name      = (String) body.get("name");
        double price     = Double.parseDouble(body.get("price").toString());
        int qty          = Integer.parseInt(body.get("qty").toString());
        return ResponseEntity.ok(cartService.addItem(userId, productId, name, price, qty));
    }

    @PutMapping("/{userId}/items/{productId}")
    public ResponseEntity<Cart> updateQty(@PathVariable String userId,
                                          @PathVariable String productId,
                                          @RequestBody Map<String, Integer> body) {
        return ResponseEntity.ok(cartService.updateQty(userId, productId, body.get("qty")));
    }

    @DeleteMapping("/{userId}/items/{productId}")
    public ResponseEntity<Cart> removeItem(@PathVariable String userId,
                                           @PathVariable String productId) {
        return ResponseEntity.ok(cartService.removeItem(userId, productId));
    }

    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> clearCart(@PathVariable String userId) {
        cartService.clearCart(userId);
        return ResponseEntity.noContent().build();
    }
}
"@

# application.properties
Set-Content -Path "src\main\resources\application.properties" -Encoding UTF8 -Value @"
spring.application.name=mcart-cart-service
server.port=8081

# PostgreSQL
spring.datasource.url=jdbc:postgresql://`${DB_HOST:localhost}:5432/mcart_cart
spring.datasource.username=`${DB_USER:postgres}
spring.datasource.password=`${DB_PASS:postgres}
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA - auto creates tables on startup
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
"@

# Dockerfile
Set-Content -Path "Dockerfile" -Encoding UTF8 -Value @"
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn clean package -DskipTests -q

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
RUN addgroup -S mcart && adduser -S mcart -G mcart
USER mcart
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
"@

Write-Host ""
Write-Host "All files created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Yellow
Get-ChildItem -Recurse -Filter "*.java" | Select-Object FullName
Write-Host ""
Write-Host "Now update pom.xml - replace dependencies section" -ForegroundColor Yellow
