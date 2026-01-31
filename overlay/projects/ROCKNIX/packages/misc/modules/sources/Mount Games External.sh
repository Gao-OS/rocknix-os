#!/bin/sh

. /etc/profile

echo "Mounting external games storage..."
systemctl start mount-games-external.service
echo "Done. Restarting EmulationStation..."
sleep 2
systemctl restart ${UI_SERVICE}
