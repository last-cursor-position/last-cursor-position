
// Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
//
// To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
// or `fdescribe`). Remove the `f` to unfocus the block.

// Just a starting point
describe('activation', () => {
  beforeEach(async () => {
    jasmine.attachToDOM(atom.views.getView(atom.workspace))
    /*    Activation     */
    // Trigger deferred activation
    atom.packages.triggerDeferredActivationHooks()
    // Activate activation hook
    atom.packages.triggerActivationHook('core:loaded-shell-environment')

    // Activate the package
    await atom.packages.activatePackage('last-cursor-position')
  })

  it('Activation', async function () {
    expect(atom.packages.isPackageLoaded('last-cursor-position')).toBeTruthy()
  })
})
