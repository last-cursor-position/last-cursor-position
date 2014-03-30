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
         ed = atom.workspace.getActiveEditor()
         if ed? and @rewinding is false and @forwarding is false
            pos = ed.getCursorBufferPosition()
            @positionHistory.push({editor: ed, position: pos})
            #future positions get invalidated when cursor moves to a new position
            @positionFuture = []
            @wasrewinding = false
            @wasforwarding = false
         @rewinding = false
         @forwarding = false
      #record starting position
      ed = atom.workspace.getActiveEditor()
      if ed?
         pos = ed.getCursorBufferPosition()
         @positionHistory.push({editor: ed, position: pos})
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
         if pos.editor isnt atom.workspace.getActiveEditor()
            testededitors = [atom.workspace.getActiveEditor()]
            until atom.workspace.getActiveEditor() is pos.editor
               atom.workspaceView.getActivePane().activateNextItem()
               if atom.workspace.getActiveEditor() in testededitors
                  #that editor does not exist anymore... reset history
                  positionHistory = []
                  foundeditor = false
                  break
               testededitors.push(atom.workspace.getActiveEditor())
         if foundeditor
            #move cursor to last position and scroll to it
            atom.workspace.getActiveEditor().setCursorBufferPosition(pos.position)

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
         if pos.editor isnt atom.workspace.getActiveEditor()
            testededitors = [atom.workspace.getActiveEditor()]
            until atom.workspace.getActiveEditor() is pos.editor
               atom.workspaceView.getActivePane().activateNextItem()
               if atom.workspace.getActiveEditor() in testededitors
                  #that editor does not exist anymore... reset future
                  positionFuture = []
                  foundeditor = false
                  break
               testededitors.push(atom.workspace.getActiveEditor())
         if foundeditor
            #move cursor to last position and scroll to it
            atom.workspace.getActiveEditor().setCursorBufferPosition(pos.position)
