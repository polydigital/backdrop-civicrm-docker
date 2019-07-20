#!/bin/bash
./wait-for-it/wait-for-it.sh $BACKDROP_DB_HOST:$BACKDROP_DB_PORT


# this entrpoint to docker container for backdrop will check for
# backdrop webserver files and if they don't exist then it will
# install via composer and copy the files to the relevant places
#
# the environment variables are created on container creation and for
# development purposes are stored in .env file - see template.env

install_backdrop(){
    ./vendor/bin/drush cc drush
    cp -r ./vendor/tabroughton/backdrop ./build
    cp -r ./vendor/backdrop/drush ./.drush/commands

    # the following is required to work around issue #2
    # when fix is merged upstream we can remove this hack
    cp ./install.inc ./build/core/includes/ #remove this file when fixed 
    
    ./vendor/bin/drush --root=build si \
	  --account-mail=tom@polydigital.co.uk \
	  --db-url=mysql://$BACKDROP_DB_USER:$BACKDROP_DB_PASSWORD@$BACKDROP_DB_HOST:$BACKDROP_DB_PORT/$BACKDROP_DB_NAME

    ./vendor/bin/drush --root=build user-password admin --password=$BACKDROP_ADMIN_PASSWORD
}

# let's check to see if composer has already installed the files
if [ ! -f ./vendor/backdrop/backdrop/settings.php ]; then
    composer install
fi

# if our the webserver files don't exist then we need to deploy them
# from the container
if [ ! -f /var/www/html/build/settings.php ]; then
    install_backdrop
fi

# this section is copied from the php:fpm official docker image
# entrypoint and has decreased the speed of container stop/restart time
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

exec "$@"
