#!/bin/sh

CIVI_CRON="http://${CIVICRM_HOSTNAME}:8080/modules/civicrm/extern/rest.php"
POST_DATA="-d entity=Job -d action=execute -d api_key=${ADMIN_API_KEY} -d key=${CIVICRM_SITE_KEY} -d json={}"

curl -s -S ${POST_DATA} ${CIVI_CRON}
