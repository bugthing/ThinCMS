
App.MongoDoc = Ember.Object.extend({

    mcoll: Ember.required(),

    load: function(){
        var id = this.get('id');
        if ( typeof(id) !== 'undefined' ) {

            var self = this;
            $.ajax({
                url: this._URL,
                type: 'GET',
                dataType: 'json',
                data: data,
                contentType: 'application/json',
                processData: false,
                success: function(data) {
                    alert('load');
                },
                error: function() {
                    alert('Could not load entry');
                }
            });

        }
    },
    save: function(){

        var type = 'POST';
        if ( this.get('_hasID') ) type = 'PUT';

        var fields = ['title', 'content'];
        var data = JSON.stringify({
            title: this.get('title'),
            content: this.get('content'),
        });

        var self = this;
        $.ajax({
            url: this.get('_URL'),
            type: type,
            dataType: 'json',
            data: data,
            contentType: 'application/json',
            processData: false,
            success: function(data) {

                if ( data.ok == 1 ) {
                    var id;
                    for(var key in data["_id"] ){ id = data["_id"][key]; }
                    self.set('id', id);
                    alert('saved:' + id );
                }
            },
            error: function() {
                alert('Could not save entry');
            }
        });
    },
    delete: function(){
        if ( ! this.get('_hasID') ) {
            alert('Could not delete new entry');
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
                if ( data.ok == 1 ) {
                    self.set('id', null);
                    alert('deleted');
                }
            },
            error: function() {
                alert('Could not delet entry');
            }
        });
    },

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
    fields: ['title', 'content']
});

App.ContentType = Ember.Object.extend({
    id: null,
    name: null
});


