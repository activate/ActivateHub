Activation Calendar
===================

Setup
-----

Note: these install steps need to be checked. Please provide feedback on anything that didn't work and workarounds you used.

* Install git.  (`apt-get install git` on Ubuntu).
* Fork the repo on github and check it out locally.
* You'll need Ruby 1.8.* or 1.9.*. and Ruby Gems. If you have a Mac, you may already have these installed. On Linux, you can install them through the package manager. Most professional Ruby programmers seem to use [RVM](http://beginrescueend.com/) to compile their own Ruby. Take the route you feel most comfortable with, you can always change later.
* `gem install bundler`
* `cd` to the project root
* To install project dependencies, run `bundle`
* Initialize your environment: `rake db:migrate db:test:prepare`
* Start the server in development mode: `rails server`. You can now see the site at http://localhost:3000
* Run the test suite: `rake`

Verify Setup
------------
Run 'rails db' and it drops you in sqlite3 command, where the `.database` and `.tables` sqlite3 commands show that you have some tables in the development.sqlite3 database (which, prior to runnining `bundle exec rake db:migrate db:test:prepare` in the Calagator development instructions was empty):
    shark@eos:~/dev/activation_calendar(activate_theme)$ rails db
    SQLite version 3.7.4
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite> .database
    seq  name             file
    ---  ---------------  ----------------------------------------------------------
    0    main             /home/shark/dev/activation_calendar/db/development.sqlite3
    sqlite> .tables
    events             sources            tags               venues
    schema_migrations  taggings           updates            versions



Development Conventions
-----------------------
* Implement new features on feature branches in git (ex: `git checkout -b full-calendalar` ... hackhackhack... `git commit; git checkout master; git merge full-calendar`).

Model Notes
-----------------------
Calagator comes with Events, Tags, Venues, and Sources.  Activate makes the following modifications:
 * New model added: Organization (which can have Sources and Events).
 * Tags on Events and Venues stores the information for Type, Topics, and Neighborhood, like so:
   * A tag is stored like type:protest on an Event to represent a Protest.
   * A tag is stored like 'beekeeping' on an Event to represent the 'beekeeping' Topic.
   * A tag is stored like 'hood:SW' on a Venue to represent the SW Neighborhood.

See Also
--------
 * Logo files are in dropbox.  Lindsay can share with you if necessary.
 * Issues / stories are in Pivotal Tracker. https://www.pivotaltracker.com/projects/365511

Submitting code changes
-----------------------
Once you have made changes to the code, you can do a pull request.
Or, if you have push permission, you can run:
    git push origin name-of-your-feature-branch
    
Deployment recipe
-----------------

Outline: (flesh out later)

 * push
 * merge
 * tag
 * pull (server)
 * stop server
 * db migrations
 * clear cache
 * start server


