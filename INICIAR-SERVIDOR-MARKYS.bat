@echo off
title MARKYS - Servidor de Rede Local
cd /d "%~dp0"
echo Iniciando servidor local do MARKYS na porta 2222...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor-markys.ps1"
if errorlevel 1 (
  echo.
  echo O servidor foi encerrado com erro. Confira as instrucoes de rede local.
  pause
)
