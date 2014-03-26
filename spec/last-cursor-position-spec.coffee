lastCursorPosition = require '../lib/last-cursor-position'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "lastCursorPosition", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('lastCursorPosition')

  describe "when the last-cursor-position:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.last-cursor-position')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'last-cursor-position:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.last-cursor-position')).toExist()
        atom.workspaceView.trigger 'last-cursor-position:toggle'
        expect(atom.workspaceView.find('.last-cursor-position')).not.toExist()
