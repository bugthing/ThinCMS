
App.ContentType = Ember.Object.extend({
    id: null,
    name: null
});
App.Entry = Ember.Object.extend({
    id: null,
    title: null,
    content: null,

    save: function(){

        var type = 'POST';
        var url = '/mongodb/testdb/entrys';
        var data = JSON.stringify({
            title: this.get('title'),
            content: this.get('content'),
        });

        var id = this.get('id');
        if ( typeof(id) !== 'undefined' ) {
            type = 'PUT';
            url = '/mongodb/testdb/entrys/' + id;
        }

        var self = this;
        $.ajax({
            url: url,
            type: type,
            dataType: 'json',
            data: data,
            contentType: 'application/json',
            processData: false,
            success: function(data) {
                alert('saved');
          },
          error: function() {
              alert('Could not save entry');
          }
        });
    }
});

App.contentTypeController = Ember.ArrayController.create({
    content: [ null,
        App.ContentType.create({id: 1, name: 'Blog'}),
        App.ContentType.create({id: 2, name: 'Events'}),
        App.ContentType.create({id: 3, name: 'Page'}) 
    ] 
});

App.selectedContentTypeController = Ember.Object.create({
    contentType: null,
    changedSelection: function() {
	    App.entrysController.loadEntrys();
    }.observes('contentType')
});

App.entrysController = Ember.ArrayController.create({
    content: [],
    contentType: function() {
        return App.selectedContentTypeController.get('contentType');
    }.property('App.selectedContentTypeController.contentType'),
    loadEntrys: function() {

	    if ( this.get('contentType') == null ) {
            this.set('content', [] );
            return;
	    }

        var self = this;
        $.ajax({
            url: '/mongodb/testdb/entrys',
            dataType: 'json',
            success: function(data) {
	            var entrys = new Array();
                for( var i=0; i<data.rows.length; i++ ) {
                    var row = data.rows[i];

                    var id;
                    for(var key in row["_id"] ){ id = row["_id"][key]; }

	                entrys.push( App.Entry.create({ 
                        id: id,
                        title: row["title"],
                        content: row["content"]
                    }));
                }
                self.set('content', entrys);
            },
            error: function() {
                alert('Could not load entrys');
            }
        });
    },
    newEntry: function() {
        this.pushObject( App.Entry.create({ 
            id: 12, 
            title: "New Entry",  
            content: "Some new content"
        }))
    }
});

App.selectedEntryController = Ember.Object.create({
    entry: null,
    updateEntry: function() {
        alert('test:' + this.entry.title )
        this.entry.save();
    }
})
