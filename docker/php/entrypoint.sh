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

    # TODO: set permissions on backdrop files and directories
    
    echo "installing civicrm"
    cp -r ./vendor/tabroughton/civicrm ./build/modules/civicrm
    
    # currently using local file copied from dev backdrop civcrm drush
    cp ./vendor/polydigital/civicrm-backdrop/drush/civicrm.drush.inc ./.drush/commands/
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

    # set permissions on civicrm files
    chmod 765 ./build/files/civicrm
    chmod 760 ./build/files/civicrm/ConfigAndLog/CiviCRM.*.log
    chmod -R 760 build/files/civicrm/upload/
    chmod -R 760 build/files/civicrm/custom/

    # this is the command to run as cron job
    # it may be better for the host to run the cron
    # see issue #14
    ./vendor/bin/drush civicrm-api job.execute \
		       -r ./build \
		       -l $CIVICRM_HOSTNAME:8080 \
		       -u admin
}

# let's check to see if composer has already installed the files
if [ ! -f ./vendor/tabroughton/backdrop/settings.php ]; then
    composer install
fi

# if our the webserver files don't exist then we need to deploy them
# from the container
if [ ! -f /var/www/build/settings.php ]; then
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
