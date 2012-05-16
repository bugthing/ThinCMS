
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
        this.$().datepicker();
    }
});
App.Button = Ember.Button.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
        this.$().button();
    }
});


/* 
 * ContentTypeSelectView - Drop down of content types.
 *   Inherits from Ember.Select and uses 2 controllers
 */
App.ContentTypeSelectView = App.Select.extend({
    contentBinding:	  "App.contentTypeController",                      // source of options
    selectionBinding: "App.selectedContentTypeController.contentType",  // set when selected
    optionLabelPath:  "content.name",                                   // label
    optionValuePath:  "content.name"                                    // value
});

/* 
 * EntryListView - List Entry's, called mutliple times
 *   When clicked tells App.selectedEntryController to select the entry.
 */
App.EntryListView = Ember.View.extend({
    entry: null,
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    classNameBindings: ['isSelected'],

    click: function() {
      var entry = this.get('entry');
      App.selectedEntryController.selectEntry(entry)
    },
    touchEnd: function() { this.click(); },

    isSelected: function() {
      var selectedItem = App.selectedEntryController.get('entry');
      var entry = this.get('entry');
      if (entry === selectedItem) { return true; }
      return false;
    }.property('App.selectedEntryController.entry'),
});

/* 
 * This view handles the display of the selected Entry
 */
App.EntryView = Ember.View.extend({
    entryBinding: 'App.selectedEntryController.entry',
});

