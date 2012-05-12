
App.ContentTypeSelectView = Em.Select.extend({
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

//App.EntryView = Ember.ContainerView.create({
//    entryBinding: 'App.selectedEntryController.entry',
//    childViews: [ Ember.View.create({ entry: this.entry }) ]
//});


