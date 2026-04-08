@echo off
color 0A
title Tunnel Ngrok Dynamique (Proxy)
echo ==============================================================
echo [Gestion Stock] Lancement du Proxy et de Ngrok...
echo ==============================================================
echo.

:: 1. Lancer le proxy Node.js dans une nouvelle fenêtre
echo Lancement du Proxy sur le port 9000...
start "PROXY SERVER" /d "D:\projetPfe" node mobile_proxy.js

:: 2. Attendre 2 secondes que le proxy soit prêt
timeout /t 2 /nobreak > nul

:: 3. Lancer Ngrok sur le port du proxy (9000)
echo Lancement du tunnel Ngrok...
cd /d "D:\cours\stage pfe"
ngrok.exe http --domain=nontrigonometrical-danita-nonperforming.ngrok-free.dev 9000

pause