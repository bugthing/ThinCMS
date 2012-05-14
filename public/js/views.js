
App.Button = Ember.Button.extend({
    classNames: ["terminput", "termbutton"],
});

App.ContentTypeSelectView = Ember.Select.extend({
    contentBinding:	"App.contentTypeController",
    selectionBinding:	"App.selectedContentTypeController.contentType",
    optionLabelPath:	"content.name",
    optionValuePath:	"content.id"
});

App.EntryListView = Ember.View.extend({
    entry: null,
    classNameBindings: ['isSelected'],

    click: function() {
      var entry = this.get('entry');
      App.selectedEntryController.set('entry', entry);
    },
    touchEnd: function() {
      this.click();
    },

    isSelected: function() {
      var selectedItem = App.selectedEntryController.get('entry');
      var entry = this.get('entry');
      if (entry === selectedItem) { return true; }
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
