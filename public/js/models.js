
App.MongoDoc = Ember.Object.extend({

    mcoll: Ember.required(),    // name of mongo collection to use.
    id: Ember.required(),       // id of the mongo document.
    fields: Ember.required(),   // list of fields saved and loaded.
    
    load: function(){
        var id = this.get('id');
        if ( typeof(id) !== 'undefined' ) {
            var self = this;
            $.ajax({
                url: this.get('_URL'),
                type: 'GET',
                dataType: 'json',
                contentType: 'application/json',
                processData: false,
                success: function(data) {

                    Ember.beginPropertyChanges(self);
                    var flds = self.get('fields');
                    for(var i=0; i< flds.length; i++) {
                        var f = flds[i];
                        self.set( f, data[f] );
                        self.addObserver( f, function(){ self.set( '_isFreshLoad', false ) } );
                    }
                    Ember.endPropertyChanges(self);
                    self.set( '_isFreshLoad', true );
                },
                error: function() {
                    alert('Could not load entry');
                }
            });
        }
        else
        {
            // cant load info without ID..
        }
    },
    save: function(){

        var type = 'POST';
        if ( this.get('_hasID') ) type = 'PUT';

        var flds = this.get('fields');
        var data = {};
        for(var i=0; i< flds.length; i++) {
            var f = flds[i];
            data[f] = this.get(f);
        }

        var self = this;
        $.ajax({
            url: this.get('_URL'),
            type: type,
            dataType: 'json',
            "data": JSON.stringify( data ),
            contentType: 'application/json',
            processData: false,
            success: function(data) {
                if ( data.ok == 1 ) {
                    var id;
                    for(var key in data["_id"] ){ id = data["_id"][key]; }
                    self.set('id', id);
                    self.set( '_isFreshLoad', true );
                }
            },
            error: function() {
                alert('Could not save entry');
            }
        });
    },
    delete: function(){
        if ( ! this.get('_hasID') ) {
            alert('Could not delete without ID');
            return false;
        }
        var self = this;
        $.ajax({
            url: this.get('_URL'),
            type: 'DEL',
            dataType: 'json',
            contentType: 'application/json',
            processData: false,
            success: function(data) {
                if ( data.ok == 1 ) self.set('id', null);
            },
            error: function() {
                alert('Could not delete entry');
            }
        });
    },

    // internally used properties

    _isFreshLoad: false,
    _hasID: function() {
        var id = this.get('id');
        if ( typeof(id) !== 'undefined' ) return true;
        return false;
    }.property(),
    _URL: function() {
        var url = '/mongodb/' + App.get('mdb') + '/' + this.get('mcoll');
        if ( this.get('_hasID') ) url = url + '/' + this.get('id');
        return url;
    }.property()
});

App.Entry = App.MongoDoc.extend({ title: "New Entry" });

App.ContentType = Ember.Object.extend({
    name: Ember.required(), 
    cfg: { elements: {} }, // cfg: { elements: { 'title': {type: 'Text'}, 'content': {type: 'LargeText'} } }

    // these are dynamicly generated propertys and a used as helper methods when 
    // constructing MongoDoc based objects (see above)

    mcoll: function() {
        return this.get('name');
    }.property('name'),

    elements: function() {
        return this.get('cfg').elements;
    }.property('cfg'),

    fields: function() {
        var flds = new Array();
        var elements = this.get('elements');
        for(var i=0; i < elements.length; i++ ) {
            var n = elements[i].name;
            flds.push(n);
        }
        return flds;
    }.property('cfg'),


    // rows are obtained from the server, this property and function
    // fetches the rows and fills out the array.

    rows: [],
    fetchRows : function() {
        var mcoll = this.get('mcoll');
        var self = this;
        $.ajax({
            url: '/mongodb/' + App.get('mdb') + '/' + mcoll,
            dataType: 'json',
            success: function(data) {
                var rows = new Array();
                for( var i=0; i<data.rows.length; i++ ) {
                    var row = data.rows[i];

                    var id;
                    for(var key in row["_id"] ){ id = row["_id"][key]; }
                    rows.push({
                        "id": id,
                        title: row["title"]
                    });
                }
                self.set('rows', rows);
            },
            error: function() {
                alert('Could not load entrys');
            }
        });
    }
});

