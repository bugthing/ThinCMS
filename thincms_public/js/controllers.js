
/*
 * This controllers builds and holds EntryType objects.
App.entryTypeController = Ember.ArrayController.create({
    content: [ Ember.Object.create({ id: 0, name:'-- please select --'}),
        App.EntryType.create({
            name: 'Blog',
            fields: ['title','content','date'],
            cfg: { elements: { 
                'title': {type: 'Text'}, 
                'content': {type: 'LargeText'},
                'date': {type: 'Date'} 
            } }
        }),
        App.EntryType.create({
            name: 'Events',
            fields: ['title','content'],
            cfg: { elements: { 'title': {type: 'Text'}, 'content': {type: 'LargeText'} } }
        }),
        App.EntryType.create({
            name: 'Page',
            fields: ['title','content'],
            cfg: { elements: { 'title': {type: 'Text'}, 'content': {type: 'LargeText'} } }
        }) ,
        App.EntryType.create({
            name: 'Dan',
            fields: ['title','date'],
            cfg: { elements: { 'title': {type: 'Text'}, 'date': {type: 'Date'} } }
        }) 
    ],
});
 */

/*
 * This controller holds the selected EntryType object and fires when 
 * EntryType is changed..
 */
App.selectedEntryTypeController = Ember.Object.create({
    entryType: null,
    changedSelection: function() {
        App.selectedEntryController.clearEntry(); // clear any entry being edited.
	    App.entrysController.loadEntrys(); // load list of entrys 
    }.observes('entryType')
});

/*
 * This controller holds the list of Entry's that is of the selected EntryType.
 */
App.entrysController = Ember.ArrayController.create({
    content: [],

    entryType: function() {
        if ( App.selectedEntryTypeController.get('entryType') == null || App.selectedEntryTypeController.get('entryType').id == 0 ) {
            return null;
        }
        return App.selectedEntryTypeController.get('entryType');
    }.property('App.selectedEntryTypeController.entryType'),

    loadEntrys: function() {

        this.set('content', [] );

	    if ( this.get('entryType') == null ) return;

        var mcoll = this.get('entryType').get('mcoll');

        var self = this;

        // fetch rows.. build App.Entry models and add to this controller..
        this.get('entryType').set('rows', []);
        this.get('entryType').addObserver('rows', function() {
            var rows = self.get('entryType').get('rows');
	        var entrys = new Array();
            for( var i=0; i<rows.length; i++ ) {
                var row = rows[i];
	            var entry = App.Entry.create({ 
                    entryType: self.get('entryType'),
                    id: row["id"],
                    title: row["title"]
                });
	            entrys.push( entry );
            }
            self.set('content', entrys);
        });
        this.get('entryType').fetchRows();
    },
    newEntry: function() {
        this.pushObject( App.Entry.create({ 
            entryType: this.get('entryType'),
        }));
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

        var ct = App.entrysController.get('entryType');

        var views = new Array();

        var entry = this.get('entry');
        if (entry == null) return false;
        
        var flds = entry.get('fields');
        var cfgs = ct.get('elements');

        for(var i=0; i< flds.length; i++) {
            var f = flds[i];

            // find config for this field..
            var c;
            for(var x=0; x< cfgs.length; x++) {
                if ( cfgs[x].name == f ) c = cfgs[x];
            }

            if ( ! c ) {
                console.debug("Could not find config for element:" + f)
                continue;
            }

            var t = c.type;

            if ( ! t ) {
                console.debug("Could not find type for element:" + f)
                continue;
            }

            var v;
            var v = eval("App." + t + "Field.extend({ valueBinding: 'App.selectedEntryController.entry." + f + "' })");;

            views.push( v );
        }
        return views;
    }.property('entry')

});
