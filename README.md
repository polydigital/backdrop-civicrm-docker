## Set up a dev URL on host machine

* `sudo echo >> civicrm.local 127.0.0.1`

## Install Backdrop-civcrm

* `cp template.env .env` and edit
* `docker-compose up -d`

## Access in browser

* <http://civicrm.local:8080>
* admin user is admin, password set in .env
