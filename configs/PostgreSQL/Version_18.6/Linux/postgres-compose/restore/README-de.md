# Restore-Arbeitsverzeichnis

[English](README.md) · [Linux-Anleitung](../../README-de.md)

Dieses optionale Verzeichnis kann bereitgestellte Sicherungen aufnehmen. `scripts/restore.sh` erhält ein Sicherungsverzeichnis oder einen Dump-Pfad als Argument. Die private Kopie zur Vorabprüfung wird unter `TMPDIR` beziehungsweise `/tmp` angelegt; dieses Verzeichnis wird dafür nicht automatisch verwendet.

Restore-Dateien nicht einchecken. Vor dem Überschreiben werden Dump-Prüfsumme, vollständige Lesbarkeit und Datenbankname geprüft. Die passende Prüfsummendatei muss vorliegen; `CONFIRM_RESTORE` muss zum Datenbanknamen im Archiv passen. Wiederherstellung einschließlich Datenbankrechten in einer separaten Umgebung testen.
