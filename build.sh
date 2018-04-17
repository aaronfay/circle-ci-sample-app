#!/bin/bash

# Tailor this command to suit your application, *must* have the trailing '&'
node server.js &
# Download ngrok and unzip
wget -qN https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux-amd64.zip
chmod +x ngrok
# Download JSON parser for determining ngrok tunnel
wget -qN -Ojq https://stedolan.github.io/jq/download/linux64/jq
chmod +x jq
# Intialize ngrok and open tunnel to our application
./ngrok authtoken $NGROK_TOKEN
./ngrok http $APP_PORT > /dev/null &
# give ngrok a second to register URLs
sleep 5
# Grab the ngrok url to send to the API
START_URL=$(curl -s 'http://localhost:4040/api/tunnels' | ./jq -r '.tunnels[1].public_url')
echo "Using start URL: $START_URL"
# Set up a couple variables to monitor result state
STATUS='null'
SUITE_RESULT=
PASSING=
# Execute Ghost Inspector suite via API and grab the result ID
EXECUTE_URL="https://api.ghostinspector.com/v1/suites/$GI_SUITE/execute/?apiKey=$GI_API_KEY&startUrl=$START_URL&immediate=1"
echo "Executing suite: $EXECUTE_URL"
RESULT_ID=$(curl -s $EXECUTE_URL | ./jq -r '.data._id')
# for the suite result, sleep for a few seconds if it hasn't changed
echo "Polling for suite results (ID: $RESULT_ID)"
while [ "$STATUS" = 'null' ]; do
  sleep 5
  SUITE_RESULT=$(curl -s "https://api.ghostinspector.com/v1/suite-results/$RESULT_ID/?apiKey=$GI_API_KEY")
  STATUS=$(echo $SUITE_RESULT | ./jq -r '.data.passing')
  echo " - status: $STATUS"
done
# status has been updated, check results for "passing"
if [ "$(echo $SUITE_RESULT | ./jq -r '.data.passing')" != 'true' ]; then
  echo "Suite failed! ¯\_(ツ)_/¯"
  PASSING=1
else 
  echo "Suite passed! \o/"
  PASSING=0
fi
# return our passing status
exit $PASSING