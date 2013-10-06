Weava App
=====

### Starting fresh on dev

    $ rake db:create # creates the dev and test dbs
    $ rake db:migrate # creates all the tables

    $ rails server # starts the app
    $ rails server --debugger # starts the app with debugging enabled

Make sure Postgres is running first

### Deploying to prod

Assuming that you have a server set up and configured just run

    $ bundle exec cap deploy:setup
    $ bundle exec cap deploy:migrations

Note:

- deploy:setup - creates all the folders etc.
- deploy:migrations - deploys the app, runs migrations and starts it

See https://github.com/teohm/kitchen-example

### Doing Useful Stuff

Creating migrations

    $ rails generate migration MigrationName params
    $ rake db:migrate

Note

    - MigrationName is the camel case that describes what this migration does e.g. AddSessionIdToUsers
    - params is the changes you are making e.g. session_id:string
    - If both of the above a specified then rails will generate a complete migration

 