Weava App
=====

![Status](https://www.codeship.io/projects/c34fb0a0-1157-0131-db55-026770587945/status)

### Starting fresh on dev

Using,

- http://postgresapp.com/ for the database with out of box config
- http://redis.io/ for sidekiq queue with out of box config

Once all the software is installed start up the background services,

- Postgres - just start the Postgres app
- Redis `$ redis-server`
- SideKiq `$ bundle exec sidekiq`
    
Then run the following to start the app,

    $ rake db:create # creates the dev and test dbs
    $ rake db:migrate # creates all the tables

    $ rails s # starts the app
    $ rails s --debugger # starts the app with debugging enabled

### Deploying to prod

Assuming that you have a server set up and configured just run

    $ bundle exec cap deploy:setup
    $ bundle exec cap deploy:migrations # does a deploy if there isn't one and runs the migrations

    $ bundle exec cap deploy:update # seems to force an update but only from the local cache
    $ bundle exec cap deploy:update_code # updates the cached code

Note:

- if you are deploying to a non-prod server then you will need to update the server URL in the config/deploy.rb file. It might be a better idea to look into something like http://stackoverflow.com/questions/429816/how-to-deploy-to-a-single-specific-server-using-capistrano.
- deploy:setup - creates all the folders etc.
- deploy:migrations - deploys the app, runs migrations and starts it

See https://github.com/teohm/kitchen-example

### Doing Useful Stuff

Creating migrations

    $ rails generate migration MigrationName params
    $ rake db:migrate
    
Rolling back the last migration

    $ rake db:rollback

Note

- MigrationName is the camel case that describes what this migration does e.g. AddSessionIdToUsers
- params is the changes you are making e.g. session_id:string
- If both of the above a specified then rails will generate a complete migration




 
