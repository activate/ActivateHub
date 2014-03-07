ActivateHub
===========

A calendar of all the Progressive, Educational, Activist-Oriented events in your city, filterable by event type or topic. Also includes a list of local organizations, filterable by topics they work on. - [more info](http://activatehub.org/).

Mission:  Create tools that support the work of all NGOs and grassroots organizers, and empower people to change their world.


Why 
---

By releasing this code under a liberal MIT open source license, we hope to empower other people so they can better organize and participate in more events that support free sharing of information, open society, and involved citizenry.


Releases
--------

The stable releases this software are tagged with version numbers, such as `v0.20090416-ac`, that represent the date they were made. There is also a `stable` branch that points to the current stable release. We're not currently updating [CHANGES.md](CHANGES.md), so look at the commit log to find out what has changed.


Installing
----------
### Quick Setup
If you're already familiar with ruby and have rvm/rbenv/direnv/etc, this
project is pretty much set up to work from a fresh checkout:
```
git clone https://github.com/activate/ActivateHub.git
cd ActivateHub
bundle install
bundle exec rake db:setup # same as bundle exec rake db:create db:seed
bundle exec rails server -blocalhost
```

There are additional things you can set up, such as switching from SQLite
to PostgreSQL, setting up multi-tenancy, obtaining a Google API key for
displaying maps, a DISQUS key for testing comments, etc.

_Some of these feature are currently undocumented, see:
<https://github.com/activate/ActivateHub/issues/66>._

### The Longer/Older Version
Read [INSTALL.md](INSTALL.md) for details on installing the software.


Contributing
------------

Bug fixes and features are welcomed. Please fork the source code and submit a pull request: <http://github.com/activate/ActivateHub>

For issues, see [Pivotal Tracker](https://www.pivotaltracker.com/projects/365511).

Current top priorities:

* [Converting the activatehub.org site to Jekyll](https://github.com/activate/ActivateHub/issues/34)

Calagator
---------

ActivateHub is based on the [Calagator](http://calagator.org/) project [source code](http://github.com/calagator/calagator/). We merge frequently to stay close to the Calagator source. Where possible, [bugfixes](http://code.google.com/p/calagator/issues/list) should be sent back upstream, via a [pull request](http://help.github.com/pull-requests/). The Calagator [mailing list](http://groups.google.com/group/pdx-tech-calendar/) is a great resource for communicating upstream.


Contributors
------------

This free, open source software was made possible by a group of volunteers that put many hours of hard work into it. See the [CONTRIBUTORS.md](CONTRIBUTORS.md) file for details.


License
-------

This program is provided under an MIT open source license, read the [LICENSE.txt](LICENSE.txt) file for details.


Copyright
---------

Copyright (c) 2011-2014 ActivateHub
