ActivateHub
===========

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

Development Conventions
-----------------------
* Implement new features on feature branches in git (ex: `git checkout -b full-calendalar` ... hackhackhack... `git commit; git checkout master; git merge full-calendar`).

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


