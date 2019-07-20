#!/bin/bash

docker-compose down
rm -rf build/ .composer/ composer.lock .drush/ mysql/ vendor/
docker-compose up -d
docker logs -f backdrop
