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
