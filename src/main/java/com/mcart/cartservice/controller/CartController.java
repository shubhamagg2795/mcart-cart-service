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
