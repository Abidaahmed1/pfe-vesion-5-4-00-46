package com.gestionStock_backend_mobile.repository.notification;

import com.gestionStock_backend_mobile.entity.notification.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
}
