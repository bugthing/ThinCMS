
App.contentTypeController = Ember.ArrayController.create({
    content: [ Ember.Object.create({ id: 0, name:'-- please select --'}),
        App.ContentType.create({id: 1, name: 'Blog'}),
        App.ContentType.create({id: 2, name: 'Events'}),
        App.ContentType.create({id: 3, name: 'Page'}) 
    ],
});

App.selectedContentTypeController = Ember.Object.create({
    contentType: null,
    changedSelection: function() {
        App.selectedEntryController.clearEntry(); // clear any entry being edited.
	    App.entrysController.loadEntrys(); // load list of entrys 
    }.observes('contentType')
});

App.entrysController = Ember.ArrayController.create({
    content: [],

    mcoll: function() {
        if ( App.selectedContentTypeController.get('contentType') == null || App.selectedContentTypeController.get('contentType').id == 0 ) {
            return null;
        }
        return App.selectedContentTypeController.get('contentType').name;
    }.property('App.selectedContentTypeController.contentType'),

    loadEntrys: function() {

	    if ( this.get('mcoll') == null ) {
            this.set('content', [] );
            return;
	    }

        var mcoll = this.get('mcoll');

        var self = this;
        $.ajax({
            url: '/mongodb/' + App.get('mdb') + '/' + mcoll,
            dataType: 'json',
            success: function(data) {
	            var entrys = new Array();
                for( var i=0; i<data.rows.length; i++ ) {
                    var row = data.rows[i];

                    var id;
                    for(var key in row["_id"] ){ id = row["_id"][key]; }

	                var entry = App.Entry.create({ 
                        mcoll: mcoll,
                        "id": id,
                        title: row["title"]
                    });
	                entrys.push( entry );
                }
                self.set('content', entrys);
            },
            error: function() {
                alert('Could not load entrys');
            }
        });
    },
    newEntry: function() {
        this.pushObject( App.Entry.create({ mcoll: this.get('mcoll') }) )
    },
    removeEntry: function(entry) {
        this.removeObject(entry);
    }
});

App.selectedEntryController = Ember.Object.create({
    entry: Ember.required(),
    clearEntry: function() {
        if ( this.get('entry') !== null) {
            App.entrysController.removeEntry( this.entry );
            this.set('entry', null);
        }
    },
    updateEntry: function() { this.entry.save(); },
    deleteEntry: function() { 
        this.entry.delete();
        this.clearEntry();
    }
})
