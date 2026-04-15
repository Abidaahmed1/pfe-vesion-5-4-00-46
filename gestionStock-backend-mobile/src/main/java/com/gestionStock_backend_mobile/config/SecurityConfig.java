package com.gestionStock_backend_mobile.config;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

	@Autowired
	private JwtAuthConverter jwtAuthConverter;

	@Bean
	public org.springframework.web.filter.OncePerRequestFilter requestLoggingFilter() {
		return new org.springframework.web.filter.OncePerRequestFilter() {
			@Override
			protected void doFilterInternal(jakarta.servlet.http.HttpServletRequest request,
					jakarta.servlet.http.HttpServletResponse response, jakarta.servlet.FilterChain filterChain)
					throws jakarta.servlet.ServletException, java.io.IOException {
				System.out.println("[BACKEND-LOG] " + request.getMethod() + " " + request.getRequestURI());
				filterChain.doFilter(request, response);
			}
		};
	}

	@Bean
	public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

		http.csrf(csrf -> csrf.disable()).cors(cors -> cors.configurationSource(corsConfigurationSource()))
				.addFilterBefore(requestLoggingFilter(), org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class)
				.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
				.authorizeHttpRequests(auth -> auth.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
						.requestMatchers("/api/test/public").permitAll()
						.requestMatchers("/api/images/**").permitAll()
						.requestMatchers("/api/mobile/**").permitAll() // Diagnostic: autoriser tout pour le mobile
						.requestMatchers("/api/admin/**").hasRole("ADMINISTRATEUR")
						.requestMatchers("/api/**").authenticated()
						.anyRequest().permitAll())
				.oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter)));

		return http.build();
	}

	@Bean
	public CorsConfigurationSource corsConfigurationSource() {

		CorsConfiguration configuration = new CorsConfiguration();

		configuration.setAllowedOriginPatterns(List.of("*")); // For mobile, use patterns to be compatible with
																// credentials

		configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));

		configuration.setAllowedHeaders(List.of("*"));
		configuration.setAllowCredentials(true);

		UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
		source.registerCorsConfiguration("/**", configuration);

		return source;
	}
}
