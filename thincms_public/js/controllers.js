
/*
 * This controllers builds and holds ContentType objects.
 */
App.contentTypeController = Ember.ArrayController.create({
    content: [ Ember.Object.create({ id: 0, name:'-- please select --'}),
        App.ContentType.create({
            name: 'Blog',
            fields: ['title','content','date'],
            cfg: { elements: { 
                'title': {type: 'Text'}, 
                'content': {type: 'LargeText'},
                'date': {type: 'Date'} 
            } }
        }),
        App.ContentType.create({
            name: 'Events',
            fields: ['title','content'],
            cfg: { elements: { 'title': {type: 'Text'}, 'content': {type: 'LargeText'} } }
        }),
        App.ContentType.create({
            name: 'Page',
            fields: ['title','content'],
            cfg: { elements: { 'title': {type: 'Text'}, 'content': {type: 'LargeText'} } }
        }) 
    ],
});

/*
 * This controller holds the selected ContentType object and fires when 
 * ContentType is changed..
 */
App.selectedContentTypeController = Ember.Object.create({
    contentType: null,
    changedSelection: function() {
        App.selectedEntryController.clearEntry(); // clear any entry being edited.
	    App.entrysController.loadEntrys(); // load list of entrys 
    }.observes('contentType')
});

/*
 * This controller holds the list of Entry's that is of the selected ContentType.
 */
App.entrysController = Ember.ArrayController.create({
    content: [],

    contentType: function() {
        if ( App.selectedContentTypeController.get('contentType') == null || App.selectedContentTypeController.get('contentType').id == 0 ) {
            return null;
        }
        return App.selectedContentTypeController.get('contentType');
    }.property('App.selectedContentTypeController.contentType'),

    loadEntrys: function() {

        this.set('content', [] );

	    if ( this.get('contentType') == null ) return;

        var mcoll = this.get('contentType').get('mcoll');

        var self = this;

        // fetch rows.. build App.Entry models and add to this controller..
        this.get('contentType').set('rows', []);
        this.get('contentType').addObserver('rows', function() {
            var rows = self.get('contentType').get('rows');
	        var entrys = new Array();
            for( var i=0; i<rows.length; i++ ) {
                var row = rows[i];
	            var entry = App.Entry.create({ 
                    mcoll: self.get('contentType').get('mcoll'),
                    fields: self.get('contentType').get('fields'),
                    id: row["id"],
                    title: row["title"]
                });
	            entrys.push( entry );
            }
            self.set('content', entrys);
        });
        this.get('contentType').fetchRows();
    },
    newEntry: function() {
        this.pushObject( App.Entry.create({ 
            mcoll: this.get('contentType').get('mcoll'),
            fields: this.get('contentType').get('fields')
        }) )
    },
    removeEntry: function(entry) {
        this.removeObject(entry);
    }
});

/*
 * This controller looks after the selected entry from the list 
 */
App.selectedEntryController = Ember.Object.create({
    entry: Ember.required(),

    selectEntry: function( entry ) {
        // if we can load this and its not just loaded..
        if ( entry.get('_hasID') && ! entry.get('_isFreshLoad') ) {
          entry.addObserver('_isFreshLoad', function(){
              App.selectedEntryController.set('entry', entry);
          });
          entry.load();
        }
        else {
          App.selectedEntryController.set('entry', entry);
        }
    },
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
    },

    elementViews: function() {

        // this function looks at the contenttype config and uses eval to build a view object bound to
        // the corresponding field within the 'entry' controller

        var ct = App.entrysController.get('contentType');

        var views = new Array();

        var entry = this.get('entry');
        if (entry == null) return false;
        
        var flds = entry.get('fields');
        var cfgs = ct.get('elements');

        for(var i=0; i< flds.length; i++) {
            var f = flds[i];
            var c = cfgs[f];

            var t;
            if ( typeof(c) !== 'undefined' ) t = c.type;

            var v;
            var v = eval("App." + t + "Field.extend({ valueBinding: 'App.selectedEntryController.entry." + f + "' })");;

            views.push( v );
        }
        return views;
    }.property('entry')

});

