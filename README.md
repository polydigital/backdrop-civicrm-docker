## Install Backdrop

* `cp template.env .env` and edit
* `docker-compose up -d`

## Play with drush

* `docker exec backdrop ./vendor/bin/drush --root=build status`

## Access in browser

* <http://localhost:8080>
* admin user is admin, password set in .env
