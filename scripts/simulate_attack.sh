#!/bin/bash
# Simuliert einen Angriff auf ein SAP-System:
# Die Beispielzeilen aus sample-logs/audit_sim.log werden an das
# überwachte Log angehängt, sodass Wazuh sie live erkennt.
#
# Szenario: normaler Login (MUELLER) -> 5x fehlgeschlagener SAP*-Login
# -> erfolgreicher SAP*-Login -> Start von SU01 -> Benutzersperre (AUM)

sudo tee -a /var/log/sap/audit_sim.log > /dev/null < "$(dirname "$0")/../sample-logs/audit_sim.log"
echo "Angriffsszenario in /var/log/sap/audit_sim.log geschrieben."
