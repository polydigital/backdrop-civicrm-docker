# Install Backdrop

* `docker-compose up -d`
* `docker-compose exec php composer install`
* `docker-compose exec php ./vendor/bin/taskman backdrop:setup`
* `docker-compose exec php ./vendor/bin/taskman backdrop:install`

## Play with drush

* `docker-compose exec php ./vendor/bin/drush --root=build status`

Backdrop should be available at: http://127.0.0.1:8080
