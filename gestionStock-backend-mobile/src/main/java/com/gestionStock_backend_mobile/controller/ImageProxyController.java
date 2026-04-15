package com.gestionStock_backend_mobile.controller;

import com.github.sardine.Sardine;
import com.github.sardine.SardineFactory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.InputStream;
import java.net.URLConnection;

@Slf4j
@RestController
@RequestMapping("/api/images")
@CrossOrigin("*")
public class ImageProxyController {

    @Value("${nextcloud.url}")
    private String nextcloudUrl;

    @Value("${nextcloud.username}")
    private String username;

    @Value("${nextcloud.password}")
    private String password;

    @Value("${nextcloud.base-path}")
    private String basePath;

    @Value("${nextcloud.documents-folder}")
    private String documentsFolder;

    @GetMapping("/{filename}")
    public ResponseEntity<Resource> getImage(@PathVariable String filename) {
        try {
            Sardine sardine = SardineFactory.begin(username, password);
            String fullUrl = nextcloudUrl + basePath + "/" + documentsFolder + "/" + filename;
            log.debug("Fetching image from Nextcloud: {}", fullUrl);

            if (sardine.exists(fullUrl)) {
                InputStream is = sardine.get(fullUrl);

                String contentType = URLConnection.guessContentTypeFromName(filename);
                if (contentType == null) {
                    contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
                }

                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .body(new InputStreamResource(is));
            }

            log.warn("Image not found on Nextcloud: {}", fullUrl);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("Error fetching image from Nextcloud: {}", e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }
}
