
App.TextField = Ember.TextField.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
    }
});
App.LargeTextField = Ember.TextArea.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
    }
});
App.Select = Ember.Select.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"]
});
App.DateField = Ember.TextField.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
        this.$().addClass("even").datepicker();
    }
});
App.Button = Ember.Button.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
        this.$().addClass("even").button();
    }
});


App.ContentTypeSelectView = App.Select.extend({
    contentBinding:	  "App.contentTypeController",
    selectionBinding: "App.selectedContentTypeController.contentType",
    optionLabelPath:  "content.name",
    optionValuePath:  "content.id"
});

App.EntryListView = Ember.View.extend({
    entry: null,
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    classNameBindings: ['isSelected'],

    click: function() {
      var entry = this.get('entry');

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
    touchEnd: function() {
      this.click();
    },

    isSelected: function() {
      var selectedItem = App.selectedEntryController.get('entry');
      var entry = this.get('entry');

      if (entry === selectedItem) { return true; }
      return false;
    }.property('App.selectedEntryController.entry'),

});

App.EntryView = Ember.View.extend({
    entryBinding: 'App.selectedEntryController.entry',
});








// NOTES: this is a view that checks what it is going to display and forwards to appropriate template.
//App = Ember.Application.create({});
//App.Foo = Ember.Object.extend();
//App.Bar = Ember.Object.extend();
//App.ItemView = Ember.View.extend({
//    templateName: function() {
//        if (this.get("content") instanceof App.Foo) {
//            return "foo-item";
//        } else {
//            return "bar-item";
//        }
//    }.property().cacheable()
//});
//App.items = Ember.ArrayController.create({
//    content: []
//});
//App.items.pushObject(App.Foo.create({name: "foo 1"}));
//App.items.pushObject(App.Bar.create({name: "bar 1"}));
//App.items.pushObject(App.Foo.create({name: "foo 2"}));
//App.items.pushObject(App.Bar.create({name: "bar 2"}));
//
//
//<script type="text/x-handlebars" data-template-name="foo-item">
//    I'm a row of type "foo" - {{content.name}}
//</script>
//<script type="text/x-handlebars" data-template-name="bar-item">
//    I'm a row of type "bar" - {{content.name}}
//</script>
//<script type="text/x-handlebars">
//    {{#each App.items}}
//        {{view App.ItemView contentBinding="this"}}
//    {{/each}}
//</script>
