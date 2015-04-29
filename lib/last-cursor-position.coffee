{CompositeDisposable} = require 'atom'

module.exports =
   positionHistory: []
   positionFuture: []
   wasrewinding: false
   rewinding: false
   wasforwarding:false
   forwarding: false
   editorSubscription: null

   activate: ->
      @disposables = new CompositeDisposable

      #ask to be called for every existing text editor, as well as for any future one
      @disposables.add atom.workspace.observeTextEditors (activeEd) =>
         #console.log("adding observed editor " + activeEd.id)
         #ask to be called for every cursor change in that editor
         activeEd.onDidChangeCursorPosition (event) =>
            #console.log("cursor moved")
            activePane = atom.workspace.getActivePane()

            if @rewinding is false and @forwarding is false
               if @positionHistory.length
                  {pane: lastPane, editor: lastEd, position: lastPos} = @positionHistory[-1..-1][0]
                  if activePane is lastPane and activeEd is lastEd and
                        #ignore cursor pos changes < 3 lines
                        Math.abs(lastPos.serialize()[0] - event.newBufferPosition.serialize()[0]) < 3
                     return
               #console.log("ActivePane id " + activePane.id)
               @positionHistory.push({pane: activePane, editor: activeEd, position: event.newBufferPosition})

               #future positions get invalidated when cursor moves to a new position
               @positionFuture = []
               @wasrewinding = false
               @wasforwarding = false
            @rewinding = false
            @forwarding = false

      #clean history when pane is removed
      @disposables.add atom.workspace.onDidDestroyPane (event) =>
         @positionHistory = (pos for pos in @positionHistory when pos.pane != event.pane)
         @positionFuture = (pos for pos in @positionFuture when pos.pane != event.pane)

      #clean history when paneItem (tab) is removed
      @disposables.add atom.workspace.onDidDestroyPaneItem (event) =>
         @positionHistory = (pos for pos in @positionHistory when pos.editor != event.item)
         @positionFuture = (pos for pos in @positionFuture when pos.editor != event.item)

      #record starting position
      ed = atom.workspace.getActiveTextEditor()
      pane = atom.workspace.getActivePane()
      if pane? and ed?
         pos = ed.getCursorBufferPosition()
         @positionHistory.push({pane: pane, editor: ed, position: pos})

      #bind events to callbacks
      @disposables.add atom.commands.add 'atom-workspace',
        'last-cursor-position:previous': => @previous()
        'last-cursor-position:next': => @next()

   previous: ->
      #console.log("Previous called")
      #when changing direction, we need to store last position, but not move to it
      if @wasforwarding or @wasrewinding is false
         #console.log("--Changing direction")
         temp = @positionHistory.pop()
         if temp?
            @positionFuture.push(temp)

      #get last position in the list
      pos = @positionHistory.pop()
      if pos?
         #keep the position for opposite direction
         @positionFuture.push(pos)
         @rewinding = true
         @wasrewinding = true
         @wasforwarding = false
         foundeditor = true
         #move to right editor
         if pos.pane isnt atom.workspace.getActivePane()
            #console.log("--Activating pane " + pos.pane.id)
            pos.pane.activate()
         if pos.editor isnt atom.workspace.getActiveTextEditor()
            #console.log("--Activating editor " + pos.editor.id)
            atom.workspace.getActivePane().activateItem(pos.editor)
         #move cursor to last position and scroll to it
         #console.log("--Moving cursor to new position")
         atom.workspace.getActiveTextEditor().setCursorBufferPosition(pos.position, autoscroll:false)
         atom.workspace.getActiveTextEditor().scrollToCursorPosition(center:true)

   next: ->
      #console.log("Next called")
      #when changing direction, we need to store last position, but not move to it
      if @wasrewinding or @wasforwarding is false
         #console.log("--Changing direction")
         temp = @positionFuture.pop()
         if temp?
            @positionHistory.push(temp)
      #get last position in the list
      pos = @positionFuture.pop()
      if pos?
         #keep the position for opposite direction
         @positionHistory.push(pos)
         @forwarding = true
         @wasforwarding = true
         @wasrewinding = false
         foundeditor = true
         #move to right editor
         if pos.pane isnt atom.workspace.getActivePane
            #console.log("--Activating pane " + pos.pane.id)
            pos.pane.activate()
         if pos.editor isnt atom.workspace.getActiveTextEditor()
            #console.log("--Activating editor " + pos.editor.id)
            atom.workspace.getActivePane().activateItem(pos.editor)
         #move cursor to last position and scroll to it
         #console.log("--Moving cursor to new position")
         atom.workspace.getActiveTextEditor().setCursorBufferPosition(pos.position, autoscroll:false)
         atom.workspace.getActiveTextEditor().scrollToCursorPosition(center:true)

   deactivate: ->
      @disposables.dispose()
