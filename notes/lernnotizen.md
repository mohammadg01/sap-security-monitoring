# Lernnotizen - SAP Security Monitoring

Frage 1: Was ist ein SIEM, und was macht Wazuh konkret?

Ein SIEM (Security Information und Event Management) sammelt Protokolldateien von vielen Systemen an einer zentralen Stelle, wertet sie aus und schlägt Alarm.

Wie sehen diese Protokolldateien aus?

Beispiel aus einem Linux-Server: 

2026-09-28 20:41:13 Failed password for user admin from 192.168.1.50 
2026-09-28 20:41:15 Failed password for user admin from 192.168.1.50
2026-09-28 20:41:18 Accepted Password for user admin from 192.168.1.50

Mit SIEM schicken alle Systeme ihre Logs an einen Server, bei Wazuh an den Manager. Dort liegt alles gesammelt in einer Datenbank. So kann man alles auf einmal durchsuchen und Zusammenhänge erkennen, etwa wenn dieselbe IP-Adresse auf drei Systemen gleichzeitig Logins versucht.

In meinem Projekt ist diese zentrale Stelle Ubuntu-VM. Darauf installiere ich Wazuh, und dorthin laufen die SAP-Logs.

Was ist Wazuh?

Wazuh ist ein Open-Source-SIEM und besteht aus drei Teilen: Agent, Manager und Dashboard.

Ein Vergleich mit einem Wachdienst, der mehrere Gebäude überwacht: 

  | Wazuh | Wachdienst | Aufgabe |
  |---|---|---|
  | Agent | Kamera in jedem Gebäude | beobachtet vor Ort und schickt alles weiter weiter, bewertet aber nichts |
  | Manager | Mitarbeiter in der Zentrale | schaut sich alles an und entscheidet: normal oder verdächtig?      |
  | Dashboard | Bildschirm in der Zentrale | zeigt die Alarme an, damit ein Mensch sie sehen kann              |

Ablauf in meinem Projekt:

1. Der Agent liest das SAP-Audit-Log und schickt jede neue Zeile an den Manager. Er ist nur der Bote
2. Der Manager zerlegt die Zeile (Wer? Wann? Was?) und prüft sie gegen Regeln, zum Beispiel "Login mit SAP* -> Alarm"
3. Das Dashboard zeigt mir diesen Alarm im Browser an.

Frage 2: Was sind Decoder und Regeln in Wazuh?

Das sind die zwei Werkzeuge des Managers, also genau das "Zerlegen" und das "Prüfen" aus meinem Ablauf. 

1. Decoder: zerlegen. Eine Logzeile ist für den Computer erst mal nur Text:

Failed password for user admin from 192.168.1.50

Der Decoder zeiht die wichtigen Teile heraus und gibt ihnen Namen: 

status = Failed // user = admin // srcip = 192.168.1.50

2. Regeln: bewerten. Die Regel schaut auf diese Felder und entscheidet, ob ein Alarm nötig ist, zum Beispiel:

"status = Failed" -> Alarm, Stufe 5 (niedrig)
"5x Failed von derselben IP in 1 Minute" -> Alarm, Stufe 10 (Brute-Force-Verdacht!)"

Jede Regel hat also eine Stufe von 0 bis 15. Je höher, desto kritischer.

Wieso ist das für mein Projekt wichtig? Für Linux-Logs bringt Wazuh fertige Decoder und Regeln mit. Für SAP-Audit-Logs nicht. Die schreibe ich selbst und genau das macht mein Projekt besonders.

Ein Beispiel. Linux ist gut lesbar: 

Failed password for user admin from 192.168.1.50

SAP arbeitet mit Kürzeln (Meldungs-IDs), etwa so:

AU2 ..... 100 ..... MUELLER ....... 192.168.1.50 

(Wazuh empfängt die Zeile, versteht sie aber nicht, solange kein Decoder da ist)

Frage 3: Wie ist ein SAP-System aufgebaut?

SAP ist eine riesige Unternehmenssoftware für Buchhaltung, Einkauf, Personal usw. Für mein Projekt sind folgende Begriffe wichtig:

1. Mandant: eine abgetrennte Umgebung innerhalb eines SAP-Systems, erkennbar an einer dreistelligen Nummer wie 000, 001 odeer 100. Man kann sich das wie Wohnungen in einem Haus vorstellen: dasselbe Gebäude (das System), aber jede Wohnung hat eigene Daten und eigene Bewohner. Typisch ist zum Beispiel 100 = Firmendaten, 000 = technischer Standardmandant.

2. Benutzer: Jeder Benutzer gehört zu einem Mandanten. Der Benutzer "MUELLER" in Mandant 100 ist ein anderer als "MUELLER" in Mandant 200. Beim Login gibt man deshalb immer Mandant, Benutzer und Passwort ein.

3. Transaktion: ein Kurzbefehl, der eine Funktion in SAP öffnet, zum Beispiel:

SU01 -> Benutzer anlegen und ändern
SE38 -> Programme ausführen 
SM19 / SM20 -> Audit Log einstellen und ansehen

Für mein Projekt: Im Audit Log steht bei jedem Eintrag, welcher Benutzer in welchem Mandanten welche Transaktion gestartet hat. Ein Beispiel für eine Regel wäre dann: "Normaler Benutzer startet SU01 -> verdächtig, denn warum legt ein Lagerist neue Benutzer an?"

SAP ist in drei Schichten aufgebaut , die klassische Drei-Schichten-Architektur:
```
┌─────────────────────────────┐
│ 1. Präsentation           │  SAP GUI / Browser (Fiori)
│    → was der Mitarbeiter    │  läuft auf dem PC des Mitarbeiters
│      sieht                  │
├─────────────────────────────┤
│ 2. Applikationsserver       │  Programmlogik (in ABAP geschrieben)
│    → das eigentliche SAP    │  prüft Rechte, führt Transaktionen aus
├─────────────────────────────┤
│ 3. Datenbank                │  meist SAP HANA
│    → speichert alle Daten   │  Gehälter, Rechnungen, Benutzer …
└─────────────────────────────┘
        läuft auf: Linux-Servern (meist SUSE oder Red Hat)
```
Für mein Projekt: Das Security Audit Log wird vom Applikationsserver (Schicht 2) geschrieben, als Datei auf dem Linux Server darunter. In einem echten System System würde der Agent dort sitzen. In meinem Projekt liest er eine simulierte Audit-Log-Datei auf meiner Ubuntu-VM."

Frage 4: Was ist das Audit Log, und was steht drin? 

Das SAP Security Audit Log ist ein Protokoll, das der SAP-Applikationsserver schreibt, um sicherheitsrelevante Ereignisse festzuhalten. Darin stehen zum Beispiel Logins (erfolgreich AU1 / fehlgeschlagen AU2), gestartete Transaktionen (AU3) und Änderungen an Benutzern, und jeder Eintrag enthält Zeit, Mandant, Benutzer, Meldungs-ID und IP-Adresse.
Besonders ist, dass es standardmäßig oft ausgeschaltet ist und erst über Profilparameter aktiviert werden muss. Angesehen wird es in SAP mit SM20 bzw. RSAU_READ_LOG.


Frage 5: Warum sind SAP\* und DDIC kritische Benutzer?

Beide kommen bei jeder SAP-Installation automatisch mit und haben Vollzugriff. Das ist die Berechtigung SAP_ALL, die sozusagen der Generalschlüssel für alles ist. 

SAP*: der eingebaute Superuser, gedacht für Ersteinrichtungen. Eine gefährliche Besonderheit: Wenn man ihn löscht statt sperrt, kann man sich je nach Einstellung mit einem bekannten Standardpasswort trotzdem anmelden. 

DDIC: ein technischer Benutzer für Wartung und Updates. Er ist ebenfalls sehr mächtig.

Kritisch sind sie aus drei Gründen:

1. Sie existieren überall. Ein Angreifer muss den Benutzernamen nicht raten.
-> SAP hat diese Benutzer fest eingebaut, und zwar mit genau diesem Namen in jeder Installation weltweit. Das steht in der offiziellen SAP-Dokumentation.

2. Ihre Standardpasswörter sind ebenfalls öffentlich bekannt. Wer sie nie geändert hat, hat eine offene Tür.

3. Vollzugriff. Wer drin ist, kann alles.

Für mein Projekt: Ein Login mit SAP* oder DDIC löst in Wazuh einen Alarm hoher Stufe aus (Projekt A), und mein Checker prüft, ob beide gesperrt sind und ihre Passwörter geändert wurden (Projekt B).
