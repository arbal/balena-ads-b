#!/usr/bin/env bash
set -e

# Check if service has been disabled through the DISABLED_SERVICES environment variable.

if [[ ",$DISABLED_SERVICES," =~ ",$BALENA_SERVICE_NAME," ]]; then
        echo "$BALENA_SERVICE_NAME is manually disabled."
        sleep infinity
fi

# Verify that all the required varibles are set before starting up the application.

echo "Verifying settings..."
echo " "
sleep 2

missing_variables=false
        
# Begin defining all the required configuration variables.

[ -z "$LAT" ] && echo "Receiver latitude is missing, will abort startup." && missing_variables=true || echo "Receiver latitude is set: $LAT"
[ -z "$LON" ] && echo "Receiver longitude is missing, will abort startup." && missing_variables=true || echo "Receiver longitude is set: $LON"
[ -z "$RECEIVER_HOST" ] && echo "Receiver host is missing, will abort startup." && missing_variables=true || echo "Receiver host is set: $RECEIVER_HOST"
[ -z "$RECEIVER_PORT" ] && echo "Receiver port is missing, will abort startup." && missing_variables=true || echo "Receiver port is set: $RECEIVER_PORT"
[ -z "RECEIVER_MLAT_PORT" ] && echo "Receiver MLAT port is missing, will abort startup." && missing_variables=true || echo "Receiver MLAT port is set: $RECEIVER_MLAT_PORT"

# End defining all the required configuration variables.

echo " "

if [ "$missing_variables" = true ]
then
        echo "Settings missing, aborting..."
        echo " "
        sleep infinity
fi

echo "Settings verified, proceeding with startup."
echo " "

# Variables are verified – continue with startup procedure.

# Configure piaware according to environment variables.
/usr/bin/piaware-config allow-auto-updates no
/usr/bin/piaware-config allow-manual-updates no
/usr/bin/piaware-config	allow-mlat yes
/usr/bin/piaware-config mlat-results yes
/usr/bin/piaware-config mlat-results-format "beast,connect,${RECEIVER_HOST}:${RECEIVER_MLAT_PORT} beast,listen,30105 ext_basestation,listen,30106"
/usr/bin/piaware-config receiver-type other
/usr/bin/piaware-config receiver-host "${RECEIVER_HOST}"
/usr/bin/piaware-config receiver-port "${RECEIVER_PORT}"

# If dump978-fa is disabled through config, disable it in piaware.
if [[ "$DUMP978_ENABLED" = "true" ]]; then
	/usr/bin/piaware-config uat-receiver-type other
    /usr/bin/piaware-config uat-receiver-host dump978-fa
    /usr/bin/piaware-config uat-receiver-port 30978
else
	/usr/bin/piaware-config uat-receiver-type none

fi

# Add FlightAware Feeder ID if present.
if [ -n "${FLIGHTAWARE_FEEDER_ID}" ]; then
  /usr/bin/piaware-config feeder-id "${FLIGHTAWARE_FEEDER_ID}"
fi

# Start piaware and put it in the background.
/usr/bin/piaware -plainlog &

# Wait for any services to exit.
wait -n