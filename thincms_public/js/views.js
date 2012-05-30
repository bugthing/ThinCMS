
/* --- App.???Field ---- Dynamically created form elements --------- */

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
App.DateField = Ember.TextField.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
        this.$().datepicker();
    }
});
App.HTMLField = Ember.TextArea.extend({
    didInsertElement: function() {

        this._super();

        var self = this;
        Ember.run.schedule('actions', this, function(){
            this.$().wysiwyg({
                iFrameClass: 'ui-widget ui-corner-all thincms-jwysiwyg',
                css: {
                    background: '#FFF',
                },
                initialContent: '',
                autoGrow: true,
                autoSave: true,
                rmUnusedControls: true,
                rmUnwantedBr: true,
                replaceDivWithP: true,
                controls: {
                    bold:                 { visible: true },
                    underline:            { visible: true },
                    italic:               { visible: true },
                    h1:                   { visible: true },
                    h2:                   { visible: true },
                    h3:                   { visible: true },
                    paragraph:            { visible: true },
                    indent:               { visible: true },
                    outdent:              { visible: true },
                    increaseFontSize:     { visible: true },
                    decreaseFontSize:     { visible: true },
                    insertOrderedList:    { visible: true },
                    insertUnorderedList:  { visible: true },
                    insertHorizontalRule: { visible: true },
                    justifyCenter:        { visible: true },
                    justifyFull:          { visible: true },
                    justifyLeft:          { visible: true },
                    justifyRight:         { visible: true },
                    undo:                 { visible: true },
                    redo:                 { visible: true },
                    createLink:           { visible: true },
                }
            });

            this.$().getWysiwyg().events.bind("getContent", function (orig) {
                self.set('value', orig);
                return orig;
            });

            $('div.wysiwyg').addClass("ui-widget ui-state-default ui-corner-all forminput");
            $('div.wysiwyg ui.toolbar').css("background", "#9bcc60 !important");
        });
    }
});

/* ---------------------------- */


App.Select = Ember.Select.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"]
});
App.Button = Ember.Button.extend({
    classNames: ["ui-widget", "ui-state-default", "ui-corner-all", "forminput"],
    didInsertElement: function() {
        this.$().button();
    }
});


/* 
 * EntryTypeSelectView - Drop down of content types.
 *   Inherits from Ember.Select and uses 2 controllers
 */
App.EntryTypeSelectView = App.Select.extend({
    contentBinding:	  "App.entryTypeController",                      // source of options
    selectionBinding: "App.selectedEntryTypeController.entryType",  // set when selected
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

