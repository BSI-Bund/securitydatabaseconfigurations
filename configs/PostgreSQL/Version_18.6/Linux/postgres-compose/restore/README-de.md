# Restore-Arbeitsverzeichnis

[English](README.md) · [Linux-Anleitung](../../README-de.md)

Dieses optionale Verzeichnis kann temporäre Restore-Dateien aufnehmen. `scripts/restore.sh` erhält den Dump-Pfad als Argument und verwendet dieses Verzeichnis nicht automatisch.

Restore-Dateien nicht einchecken. Checksums prüfen und Wiederherstellung in einer separaten Umgebung testen. Das Restore-Skript überschreibt die gewählte Datenbank und verlangt deren Namen als Wert von `CONFIRM_RESTORE`.
