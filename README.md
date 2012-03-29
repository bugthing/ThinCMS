
Thin CMS
========

A Simple JS based CMS that stores data in MongoDB.

This idea behind this project to create a simple and quick-to-setup CMS system
that will allow the use to build documents in MongoDB which can then be pulled
back to construce the pages for a bespoke site.

Start
-----

# Start MongoDB

  mongod --port=47534 --dbpath=/data/mdb --rest

# Get EmberJS

  git submodule add git://github.com/emberjs/ember.js.git ./submodules/ember.js
  cd ./submodules/ember.js/
  bundle install
  rake
  cd ../../
  ln -s ../../../submodules/ember.js/dist ./public/js/libs/emberjs

# Get jQuery

  wget http://code.jquery.com/jquery-1.7.2.min.js 
  mv jquery-1.7.2.min.js ./public/js/libs/

# Use CMS

  Go to this local url: file:///path/to/thincms/public/index.html
  Create pages, containers and more to your preferences

# View your new site

  Not yet finalised, but probably something along the lines of setting up a 

  Perl Web server to server up pages build from MongoDB.
