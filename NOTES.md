
Thin CMS
========

A Simple JS based CMS that stores data in MongoDB.

This idea behind this project to create a simple and quick-to-setup CMS system
that will allow the user to build documents in MongoDB which can then be pulled
into an HTML page and displayed

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
  ln -s ../../../submodules/ember.js/dist ./thincms_public/js/libs/emberjs

# Get jQuery

  wget http://code.jquery.com/jquery-1.7.2.min.js 
  mv jquery-1.7.2.min.js ./public/js/libs/

# Get jQuery-UI - (used customer download build and chose mint choc theme)

  wget http://jqueryui.com/download/jquery-ui-1.8.20.custom.zip 
  mkdir -p ./public/js/libs/jquery-ui
  mv jquery-1.7.2.min.zip ./thincms_public/js/libs/jquery-ui

# Get jQuery WYSIWYG

  git submodule add git://github.com/akzhan/jwysiwyg.git ./submodules/jwysiwyg
  ln -s ../../../submodules/jwysiwyg ./thincms_public/js/libs/jwysiwyg

# Start the application

  MongoDB --rest API can only handle 'GET' requests, therefore there
  is a Plack::Middleware in place to GET,POST,PUT and DEL docuements
  to/from the mongo db store.  With that in mind, start the plack app:
    plackup 
  Then visit: http://0:5000/thincms/

# View your new site

  Not yet finalised, but probably something along the lines of setting up a 
  Perl Web server to server up pages build from MongoDB.


Admin Notes
-----------

# Get MongoDB
  http://fastdl.mongodb.org/linux/mongodb-linux-i686-2.0.4.tgz
  # Start MongoDB
  mongod --dbpath=$DBPATH

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

