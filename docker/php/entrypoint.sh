#!/bin/bash

# this entrpoint to docker container for backdrop will check for
# backdrop webserver files and if they don't exist then it will
# install via composer and copy the files to the relevant places
#
# the environment variables are created on container creation and for
# development purposes are stored in .env file - see template.env

install_backdrop(){
    ./vendor/bin/drush cc drush

    echo "installing backdrop"
    cp -r ./vendor/tabroughton/backdrop ./build
    cp -r ./vendor/backdrop-contrib/drush ./.drush/commands

    # we use wait for it to ensure the database is ready to connect to
    ./wait-for-it/wait-for-it.sh -t 60 $BACKDROP_DB_HOST:$BACKDROP_DB_PORT
    
    ./vendor/bin/drush cc drush
    ./vendor/bin/drush --root=build si \
	  --account-mail=$BACKDROP_ADMIN_EMAIL \
	  --db-url=mysql://$BACKDROP_DB_USER:$BACKDROP_DB_PASSWORD@$BACKDROP_DB_HOST:$BACKDROP_DB_PORT/$BACKDROP_DB_NAME

    ./vendor/bin/drush --root=build user-password admin --password=$BACKDROP_ADMIN_PASSWORD

    echo "installing civicrm"
    cp -r ./vendor/tabroughton/civicrm-backdrop ./build/modules/civicrm

    #following sed command is hack to get around issue #17
    # this will need removing if upstream pull request to add civicrm-install to whitelist is accepted
    sed -i "/  \$safe_commands = array(/a 'civicrm-install'," .drush/commands/backdrop.drush.inc
    
    # currently using local file copied from dev backdrop civcrm drush
    cp ./civicrm.drush.inc ./.drush/commands/
    ./vendor/bin/drush cc drush
    ./vendor/bin/drush cc drush --root=build

    ./vendor/bin/drush civicrm-install \
                        --root=build \
                        --dbuser=$BACKDROP_DB_USER \
                        --dbpass=$BACKDROP_DB_PASSWORD \
                        --dbhost=$CIVICRM_DB_HOST \
                        --dbname=$CIVICRM_DB_NAME \
                        --site_url=$CIVICRM_HOSTNAME:8080 \
			--load_generated_data=$CIVICRM_GENDATA
    
    mv ./.drush/commands/civicrm.drush.inc ./build/modules/civicrm/backdrop/drush/
    ./vendor/bin/drush cc drush
    ./vendor/bin/drush cc drush --root=build

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
