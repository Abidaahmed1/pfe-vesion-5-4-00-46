package com.gestionStock_backend_mobile.controller;

import com.gestionStock_backend_mobile.entity.notification.Notification;
import com.gestionStock_backend_mobile.service.UserService;
import com.gestionStock_backend_mobile.service.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/mobile/notifications")
@RequiredArgsConstructor
public class NotificationMobileController {

    private final NotificationService notificationService;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<Notification>> getNotifications() {
        String userId = userService.getCurrentUserId();
        if (userId == null) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(notificationService.getNotificationsForUser(userId));
    }

    @GetMapping("/unread")
    public ResponseEntity<List<Notification>> getUnreadNotifications() {
        String userId = userService.getCurrentUserId();
        if (userId == null) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(notificationService.getUnreadNotificationsForUser(userId));
    }

    @GetMapping("/unread/count")
    public ResponseEntity<Map<String, Integer>> getUnreadCount() {
        String userId = userService.getCurrentUserId();
        if (userId == null) return ResponseEntity.status(403).build();
        int count = notificationService.getUnreadNotificationsForUser(userId).size();
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable Long id) {
        String userId = userService.getCurrentUserId();
        if (userId == null) return ResponseEntity.status(403).build();
        notificationService.markAsRead(id, userId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead() {
        String userId = userService.getCurrentUserId();
        if (userId == null) return ResponseEntity.status(403).build();
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok().build();
    }
}
