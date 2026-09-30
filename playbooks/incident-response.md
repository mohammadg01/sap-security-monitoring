# Incident-Response-Playbooks

Diese Playbooks beschreiben, wie ein SOC-Analyst auf die SAP-Alarme aus diesem Projekt reagiert. 
Alle Schritte beziehen sich auf ein reales SAP-System. Im Projekt selbst sind die Logs simuliert.

## Playbook 1: Login mit Standardbenutzer SAP* / DDIC (Regel 100104, Stufe 12)

**Warum kritisch?** SAP* und DDIC haben Vollzugriff. Im Normalbetrieb meldet sich damit niemand an.
Ein Login ist entweder ein Angriff oder ein schwerer Verstoß gegen interne Vorgaben.

**1. Sofortmaßnahmen (erste 15 Minuten)** 
- Aktive Sitzung des Benutzers prüfen (Transaktion `SM04` / `AL08`) und beenden
- Benutzer sperren (Transaktion `SU01`)
- Quell-IP (`srcip`) an der Firewall blockieren, falls extern oder unbekannt

**2. Analyse**
- Im Audit Log (`RSAU_READ_LOG`) prüfen: Was hat der Benutzer nach dem Login getan?
- Gab es vorher fehlgeschlagene Logins (Regel 100103)? -> Hinweise auf Brute Force
- Wurden neue Benutzer angelegt oder Rechte geändert (`SUIM`, Änderungsbelege)?

**3. Eindämmung und Behebung**
- Passwort von SAP* / DDIC auf ein starkes, geheimes Passwort ändern
- Profilparameter `login/no_automatic_user_sapstar` auf '1' prüfen
- Vom Angreifer angelegte Benutzer oder Rechte entfernen

**4. Nachbereitung**
- Vorfall dokumentieren (Zeitlinie, betroffene Systeme, Maßnahmen)
- Klären, wie der Angreifer ins Netz gelangt ist

---

## Playbook 2: Brute-Force-Verdacht (Regel 100103, Stufe 10) 

**Warum kritisch?** Viele fehlgeschlagene Logins von einer IP in kurzer Zeit deuten auf automatisiertes Passwortraten hin.

**1. Sofortmaßnahmen**
- Quell-IP prüfen: intern oder extern? Bekanntes Gerät?
- Bei externer oder unbekannter IP: an der Firewall blockieren

**2. Analyse**
- Welche Benutzer wurden angegriffen? Ein Konto oder viele (Password Spraying)?
- **Wichtigste Frage:** Folgte auf die Fehlversuche ein **erfolgreicher** Login (AU1) von derselben IP?
 -> Falls ja: sofort weiter mit Playbook 1 bzw. Konto als kompromittiert behandeln

**3. Eindämmung und Behebung**
- Betroffene Konten prüfen, gegebenenfalls Passwörter zurücksetzen
- Profilparameter 'login/fails_to_user_lock' prüfen (empfohlen: ca. 5)

**4. Nachbereitung**
- Bei internen IPs: Ist ein Gerät im Netz kompromittiert?
- Schwellwert der Regel anpassen, falls es Fehlalarme gab

---

## Playbook 3: Kritische Transaktion gestartet (Regel 100105, Stufe 8)

**Warum relevant?** Transaktionen wie `SU01` (Benutzer), `PFCG` (Rollen) oder `SE38` (Programme) erlauben weitreichende Änderungen.
Normale Fachanwender brauchen sie nicht.

**1. Sofortmaßnahmen**
- Prüfen: Gehört der Benutzer zur Basis- oder Berechtigungsadministration?
  -> Falls ja und die Aktion ist erwartet: Alarm als legitim schließen und dokumentieren

**2. Analyse** (falls unerwartet) 
- Was wurde in der Transaktion geändert? (Änderungsbelege in `SUIM`)
- Warum hat der Benutzer überhaupt Zugriff auf diese Transaktion? -> zu viele Rechte

**3. Eindämmung und Behebung**
- Unberechtigte Änderungen rückgängig machen
- Rechte des Benutzers einschränken (Rolle in `PFCG` anpassen)

**4. Nachbereitung**
- Berechtigungskonzept überprüfen: Wer hat noch unnötig Zugriff auf kritische Transaktionen?
