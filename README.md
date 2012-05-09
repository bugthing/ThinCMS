
Thin CMS
========

A Simple JS based CMS that stores data in MongoDB.

This idea behind this project to create a simple and quick-to-setup CMS system
that will allow the use to build documents in MongoDB which can then be pulled
back to construce the pages for a bespoke site.

Start
-----

# Start MongoDB

  mongod --port=28017 --dbpath=/data/mdb --rest

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


Admin Notes
-----------

# Get MongoDB
  http://fastdl.mongodb.org/linux/mongodb-linux-i686-2.0.4.tgz
  # Start MongoDB
  mongod --rest --dbpath=$DBPATH

# RVM - Ruby (for emberjs build)
  https://rvm.beginrescueend.com/

Dev Notes
---------

# MongoDb REST and curl

## List data database
  curl -i -H "Accept: application/json" http://127.0.0.1:28017/databases/

## Create a document (and db and collection due to upsert issum)
  curl -i -H "Accept: application/json" -X POST -d "{firstName: 'benjamin'}" http://127.0.0.1:28017/testdb/testcoll/

## List documents
  curl -i -H "Accept: application/json" -X GET http://127.0.0.1:28017/testdb/testcoll/

## Update a document (should work, by currently does not!)
  curl -i -H "Accept: application/json" -X PUT -d "{firstName: 'ben', lastName: 'netanyaho'}" http://127.0.0.1:28017/testdb/testcoll/4f745fea8e234dad19615026
