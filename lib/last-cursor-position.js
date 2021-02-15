
const {CompositeDisposable} = require('atom');

module.exports = {
   positionHistory: [],
   positionFuture: [],
   wasrewinding: false,
   rewinding: false,
   wasforwarding:false,
   forwarding: false,
   editorSubscription: null,

   activate() {
      this.disposables = new CompositeDisposable;

      //ask to be called for every existing text editor, as well as for any future one
      this.disposables.add(atom.workspace.observeTextEditors(activeEd => {
         //console.log("adding observed editor " + activeEd.id)
         //ask to be called for every cursor change in that editor
         return activeEd.onDidChangeCursorPosition(event => {
            //console.log("cursor moved")
            const activePane = atom.workspace.getActivePane();

            if ((this.rewinding === false) && (this.forwarding === false)) {
               if (this.positionHistory.length) {
                  const {pane: lastPane, editor: lastEd, position: lastPos} = this.positionHistory.slice(-1)[0];
                  if ((activePane === lastPane) && (activeEd === lastEd) &&
                        //ignore cursor pos changes < 3 lines
                        (Math.abs(lastPos.getStartBufferPosition().serialize()[0] - event.newBufferPosition.serialize()[0]) < 3)) {
                     return;
                   }
                }
               //console.log("ActivePane id " + activePane.id)
               //position is a Marker that reamins logically stationary even as the buffer changes
               this.positionHistory.push({pane: activePane, editor: activeEd, position: activeEd.markBufferPosition(event.newBufferPosition)});

               //future positions get invalidated when cursor moves to a new position
               this.positionFuture = [];
               this.wasrewinding = false;
               this.wasforwarding = false;
             }
            this.rewinding = false;
            return this.forwarding = false;
         });
      })
      );

      //clean history when pane is removed
      this.disposables.add(atom.workspace.onDidDestroyPane(event => {
         let pos;
         this.positionHistory = ((() => {
           const result = [];
           for (pos of Array.from(this.positionHistory)) {              if (pos.pane !== event.pane) {
               result.push(pos);
             }
           }
           return result;
         })());
         return this.positionFuture = ((() => {
           const result1 = [];
           for (pos of Array.from(this.positionFuture)) {              if (pos.pane !== event.pane) {
               result1.push(pos);
             }
           }
           return result1;
         })());
      })
      );

      //clean history when paneItem (tab) is removed
      this.disposables.add(atom.workspace.onDidDestroyPaneItem(event => {
         let pos;
         this.positionHistory = ((() => {
           const result = [];
           for (pos of Array.from(this.positionHistory)) {              if (pos.editor !== event.item) {
               result.push(pos);
             }
           }
           return result;
         })());
         return this.positionFuture = ((() => {
           const result1 = [];
           for (pos of Array.from(this.positionFuture)) {              if (pos.editor !== event.item) {
               result1.push(pos);
             }
           }
           return result1;
         })());
      })
      );

      //record starting position
      const ed = atom.workspace.getActiveTextEditor();
      const pane = atom.workspace.getActivePane();
      if ((pane != null) && (ed != null)) {
         const pos = ed.getCursorBufferPosition();
         this.positionHistory.push({pane, editor: ed, position: ed.markBufferPosition(pos)});
       }

      //bind events to callbacks
      return this.disposables.add(atom.commands.add('atom-workspace', {
        'last-cursor-position:previous': () => this.previous(),
        'last-cursor-position:next': () => this.next(),
        'last-cursor-position:push': () => this.push(),
        'last-cursor-position:clear': () => this.clear(),
      }
      )
      );
    },

   push() {
      const activeEd = atom.workspace.getActiveTextEditor();
      return this.positionHistory.push({pane: atom.workspace.getActivePane(), editor: activeEd, position: activeEd.markBufferPosition(activeEd.getCursorBufferPosition())});
    },

   previous() {
      //console.log("Previous called")
      //when changing direction, we need to store last position, but not move to it
      if (this.wasforwarding || (this.wasrewinding === false)) {
         //console.log("--Changing direction")
         const temp = this.positionHistory.pop();
         if (temp != null) {
            this.positionFuture.push(temp);
          }
       }

      //get last position in the list
      const pos = this.positionHistory.pop();
      if (pos != null) {
         //keep the position for opposite direction
         this.positionFuture.push(pos);
         this.rewinding = true;
         this.wasrewinding = true;
         this.wasforwarding = false;
         const foundeditor = true;
         //move to right editor
         if (pos.pane !== atom.workspace.getActivePane()) {
            //console.log("--Activating pane " + pos.pane.id)
            pos.pane.activate();
          }
         if (pos.editor !== atom.workspace.getActiveTextEditor()) {
            //console.log("--Activating editor " + pos.editor.id)
            const activePane = atom.workspace.getActivePane();
            const editorIdx = activePane.getItems().indexOf(pos.editor);
            activePane.activateItemAtIndex(editorIdx);
          }
         //move cursor to last position and scroll to it
         //console.log("--Moving cursor to new position")
         if (pos.position) {
           atom.workspace.getActiveTextEditor().setCursorBufferPosition(pos.position.getStartBufferPosition(), {autoscroll:false});
           return atom.workspace.getActiveTextEditor().scrollToCursorPosition({center:true});
         }
       }
    },

   next() {
      //console.log("Next called")
      //when changing direction, we need to store last position, but not move to it
      if (this.wasrewinding || (this.wasforwarding === false)) {
         //console.log("--Changing direction")
         const temp = this.positionFuture.pop();
         if (temp != null) {
            this.positionHistory.push(temp);
          }
       }
      //get last position in the list
      const pos = this.positionFuture.pop();
      if (pos != null) {
         //keep the position for opposite direction
         this.positionHistory.push(pos);
         this.forwarding = true;
         this.wasforwarding = true;
         this.wasrewinding = false;
         const foundeditor = true;
         //move to right editor
         if (pos.pane !== atom.workspace.getActivePane) {
            //console.log("--Activating pane " + pos.pane.id)
            pos.pane.activate();
          }
         if (pos.editor !== atom.workspace.getActiveTextEditor()) {
            //console.log("--Activating editor " + pos.editor.id)
            const activePane = atom.workspace.getActivePane();
            const editorIdx = activePane.getItems().indexOf(pos.editor);
            activePane.activateItemAtIndex(editorIdx);
          }
         //move cursor to last position and scroll to it
         //console.log("--Moving cursor to new position")
         if (pos.position) {
           atom.workspace.getActiveTextEditor().setCursorBufferPosition(pos.position.getStartBufferPosition(), {autoscroll:false});
           return atom.workspace.getActiveTextEditor().scrollToCursorPosition({center:true});
         }
       }
    },

   deactivate() {
      return this.disposables.dispose();
    },

   clear(){
     return this.positionHistory = []
   }


 };
