#!/bin/bash

# this entrpoint to docker container for backdrop will check for
# backdrop webserver files and if they don't exist then it will
# install via composer and copy the files to the relevant places
#
# the environment variables are created on container creation and for
# development purposes are stored in .env file - see template.env

setup_default_settings(){    
    echo "Setting up default Org and Email settings..."

    ORGNAME="ACB - A Community Buinsess"
    DEFAULTEMAIL="acb@civicrm.local"

    vendor/bin/drush cvapi Contact.create id=1 \
		     sort_name="$ORGNAME" \
		     display_name="$ORGNAME" \
		     legal_name="$ORGNAME" \
		     organization_name="$ORGNAME" \
		     api_key="$ADMIN_API_KEY" \
		     --root=build
    
    vendor/bin/drush cvapi Domain.create id=1 \
		     name="$ORGNAME" \
		     description='A community business in testing'  \
		     --root=build

    # link cms user to contact - this might need to be updated so that the contact
    # is an individual rather than an organsiation in which case we would create
    # a new contact as type individual with the API key added, get the contact_id
    # and then use it in the following.  For now we will use the default contact id 1.
    vendor/bin/drush cvapi UFMatch.create uf_id=1 \
		     uf_name=$ADMIN_EMAIL \
		     contact_id=1 \
		     --root=build
    

    # There isn't a default adress so we'll creaete one
    vendor/bin/drush cvapi Address.create contact_id=1 \
		     location_type_id="Work" \
		     is_primary=1 \
		     street_address="62 Firstline Street" \
		     city="Sheffield" \
		     state_province_id="South Yorkshire" \
		     postal_code="S44 1BT" \
		     manual_geo_code=0 \
		     --root=build

    # we are yet to set up incoming email imap/pop3 but when we do we can set these in the following command
    vendor/bin/drush cvapi MailSettings.create id=1 \
		     domain_id=1 \
		     domain='civicrm.local' \
		     --root=build

    # this command is likely to break, we need to use a get from OptionGroup and use the id from that in the create statement
    # vendor/bin/drush cvapi OptionGroup.get option_group_id=31 return=id --root=build (look up the option_group_id in api first)
    vendor/bin/drush cvapi OptionValue.create id=610 \
		     option_group_id=31 \
		     label="\"ACB DEMO\" <$DEFAULTEMAIL>" \
		     is_default=1  \
		     --root=build
    
    vendor/bin/drush cvapi Email.create id=1 \
		     contact_id=1 \
		     email="$DEFAULTEMAIL"  \
		     --root=build

    # this is an example of setting up settings that have an array in it, setting.get returns an array, mailing_backend is an array within it
    echo '{"mailing_backend":{"outBound_option":"0","smtpServer":"civicrm.local","smtpPort":"2525","smtpAuth":"0","smtpUser":"","smtpPassword":""}}' \
	| ./vendor/bin/drush civicrm-api --in=json setting.create --root=build

    # the output of this get request combines Domain object with some of the others like the default email option
    vendor/bin/drush cvapi Contact.get id=1 --root=build
    vendor/bin/drush cvapi Domain.get --root=build
}

install_backdrop(){
    ./vendor/bin/drush cc drush

    echo "installing backdrop"
    cp -r ./vendor/tabroughton/backdrop ./build
    cp -r ./vendor/backdrop-contrib/drush ./.drush/commands

    # we use wait for it to ensure the database is ready to connect to
    ./wait-for-it/wait-for-it.sh -t 60 $BACKDROP_DB_HOST:$BACKDROP_DB_PORT
    
    ./vendor/bin/drush cc drush
    ./vendor/bin/drush --root=build si \
	  --account-mail=$ADMIN_EMAIL \
	  --db-url=mysql://$BACKDROP_DB_USER:$BACKDROP_DB_PASSWORD@$BACKDROP_DB_HOST:$BACKDROP_DB_PORT/$BACKDROP_DB_NAME

    ./vendor/bin/drush --root=build user-password $ADMIN_USER --password=$ADMIN_PASSWORD

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

    setup_default_settings
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
