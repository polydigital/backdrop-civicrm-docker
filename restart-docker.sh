#!/bin/bash
# I just use this to help me quickly restart my docker
# whilst I am developing - we should look at better ways
docker-compose down
rm -rf build/ composer.lock mysql/ vendor/ .drush
docker-compose up
docker logs -f backdrop
