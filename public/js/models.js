
App.MongoDoc = Ember.Object.extend({

    mcoll: Ember.required(),
    fields: Ember.required(),
    
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
                        if ( typeof(data[f]) !== 'undefined' ) {
                            self.set( f, data[f] );
                            // add observer on to object field to set '_isFreshLoad'..
                            self.addObserver( f, function(){ self.set( '_isFreshLoad', false ) } );
                        }
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

        var flds = ['title', 'content'];
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

App.Entry = App.MongoDoc.extend({
    fields: ['title', 'content'],
    title: "New Entry",
    content: "Some new content",
});

App.ContentType = Ember.Object.extend({
    id: Ember.required(),
    name: Ember.required()
});

