# Install Backdrop

* `docker-compose up -d`
* `docker-compose exec php composer install`
* `docker-compose exec php ./vendor/bin/taskman backdrop:install`

## Play with drush

* `docker-compose exec php ./vendor/bin/drush --root=build status`

Backdrop should be available at: http://127.0.0.1:8080

Login is `admin`

Password is `admin`

## Available Taskman commands:

To install Backdrop
* `docker-compose exec php ./vendor/bin/taskman backdrop:install`

To remove the files and database (_usually before installing_)
* `docker-compose exec php ./vendor/bin/taskman backdrop:reset`
