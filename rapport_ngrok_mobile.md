# Rapport d'Intervention Technique : Projet StockMasters

## I. PRÉSENTATION DU PROBLÈME (PROBLÉMATIQUE)

### 1.1 Perte d'Accès aux Données Historiques
Suite à l'implémentation de **Keycloak** pour la gestion de l'authentification, une rupture critique de la cohérence des données est apparue. L'application affichait un stock vide (0,00 €) alors que la base de données contenait plus de 80 pièces détachées.
*   **Cause** : Les données étaient liées à un identifiant utilisateur obsolète (`baca5ff1-...`), rendant les inventaires invisibles pour le nouvel utilisateur authentifié (`685fe91d-...`).

### 1.2 Conflits d'Infrastructure et Accessibilité Mobile
L'architecture initiale souffrait de plusieurs blocages techniques :
*   **Collision de Ports** : Le Backend tentait de démarrer sur des ports déjà utilisés par l'environnement de développement local, empêchant le lancement correct des services Docker.
*   **Isolement du Mobile** : L'application mobile Flutter ne parvenait pas à joindre le serveur local de manière sécurisée et constante, particulièrement lors de changements de réseaux ou de serveurs.
*   **Échec d'Authentification (401)** : Un conflit de configuration entre les adresses "locales" et les adresses "tunnélisées" Ngrok bloquait toute requête sécurisée, rendant l'application inutilisable.

---

## II. PRÉSENTATION DE LA SOLUTION (ACTIONS CORRECTIVES)

### 2.1 Réalignement de l'Identité Numérique (Identity Mapping)
La première étape a consisté à rétablir le lien de propriété entre l'utilisateur et ses données.
*   **Action** : Exécution de scripts de migration SQL pour mettre à jour les références de l'ID utilisateur dans l'ensemble du schéma de base de données (Tables `users`, `bon`, `piece_historique`).
*   **Résultat** : Restauration immédiate de la visibilité des **83 pièces détachées** sur le tableau de bord.

### 2.2 Unification de l'Architecture via Docker
Pour éliminer les conflits et garantir la portabilité, nous avons conteneurisé l'intégralité de l'écosystème :
*   **Isolation des Ports** : Attribution d'un port dédié (**8095**) pour le Backend Web afin de garantir une communication sans interférence.
*   **Standardisation du Frontend** : Mise à jour automatique de l'ensemble des modules Angular (16+ services) pour pointer vers l'infrastructure unifiée.

### 2.3 Tunneling Permanent et Sécurité Hybride
Pour assurer l'accès mobile universel, une solution de tunnel statique a été déployée :
*   **Proxy Ngrok Statique** : Mise en place d'un domaine permanent (`ngrok-free.dev`) permettant au mobile de communiquer avec le serveur local sans configuration manuelle de l'utilisateur.
*   **Configuration Multi-Issuer** : Ajustement de la sécurité Spring Boot pour valider simultanément les jetons provenant de l'interface Web (localhost) et de l'interface Mobile (Ngrok).

---

## III. CONCLUSION ET RÉSULTATS
La solution implémentée transforme une infrastructure fragile en un système **robuste et portable**. 
*   **Intégrité** : 100% des données historiques sont récupérées. ✅
*   **Mobilité** : L'application mobile fonctionne désormais sur n'importe quel réseau. ✅
*   **Agilité** : Le passage d'un serveur local à un serveur distant se fait sans modification de code. ✅

---
**Date :** 08 Avril 2026  
**Expertise Technique :** Antigravity AI Assistant
