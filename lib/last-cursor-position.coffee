module.exports =
   positionHistory: []
   positionFuture: []
   wasrewinding: false
   rewinding: false
   wasforwarding:false
   forwarding: false
   editorSubscription: null

   activate: ->
      #ask to be called back every time the cursor moves
      atom.workspaceView.on 'cursor:moved', =>
         ed = atom.workspace.getActiveTextEditor()
         pane = atom.workspace.activePane
         if ed? and @rewinding is false and @forwarding is false
            pos = ed.getCursorBufferPosition()
            if @positionHistory.length
               {pane: lastPane, editor: lastEd, position: lastPos} = @positionHistory[-1..-1][0]
               if pane is lastPane and ed is lastEd and
                     Math.abs(lastPos.serialize()[0] - pos.serialize()[0]) < 3
                  return
            @positionHistory.push({pane: pane, editor: ed, position: pos})
            #future positions get invalidated when cursor moves to a new position
            @positionFuture = []
            @wasrewinding = false
            @wasforwarding = false
         @rewinding = false
         @forwarding = false

      #clean history when pane is removed
      atom.workspaceView.on 'pane:removed', (event, removedPaneView) =>
         @positionHistory = @positionHistory.filter((pos) -> pos.pane != removedPaneView.model)

      #clean history when paneItem (tab) is removed
      atom.workspaceView.on 'pane:item-removed', (event, paneItem) =>
         @positionHistory = @positionHistory.filter((pos) -> pos.editor != paneItem)

      #record starting position
      ed = atom.workspace.getActiveTextEditor()
      pane = atom.workspace.activePane
      if pane? and ed?
         pos = ed.getCursorBufferPosition()
         @positionHistory.push({pane: pane, editor: ed, position: pos})
      #bind events to callbacks
      atom.workspaceView.command 'last-cursor-position:previous', => @previous()
      atom.workspaceView.command 'last-cursor-position:next', => @next()

   previous: ->
      #when changing direction, we need to store last position, but not move to it
      if @wasforwarding or @wasrewinding is false
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
         if pos.pane isnt atom.workspace.activePane
            pos.pane.activate()
         if pos.editor isnt atom.workspace.getActiveTextEditor()
            atom.workspace.activePane.activateItem(pos.editor)
         #move cursor to last position and scroll to it
         atom.workspace.getActiveTextEditor().setCursorBufferPosition(pos.position, autoscroll:false)
         atom.workspace.getActiveTextEditor().scrollToCursorPosition(center:true)

   next: ->
      #when changing direction, we need to store last position, but not move to it
      if @wasrewinding or @wasforwarding is false
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
         if pos.pane isnt atom.workspace.activePane
            pos.pane.activate()
         if pos.editor isnt atom.workspace.getActiveTextEditor()
            atom.workspace.activePane.activateItem(pos.editor)
         #move cursor to last position and scroll to it
         atom.workspace.getActiveTextEditor().setCursorBufferPosition(pos.position, autoscroll:false)
         atom.workspace.getActiveTextEditor().scrollToCursorPosition(center:true)
