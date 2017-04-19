{CompositeDisposable} = require 'atom'
{requirePackages}     = require 'atom-utils'
path                  = require 'path'

module.exports =
  config:
    patternExpression:
      type: 'string'
      default: '*.{ext}'

  activate: (state) ->
    unless atom.packages.isPackageActive('find-and-replace')
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'find-and-replace:toggle')
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'find-and-replace:toggle')

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable()

    # Register command that toggles this view
    @subscriptions.add(atom.commands.add 'atom-workspace',
      'find-and-replace-same-type:show': => @show()
      'find-and-replace-same-dir:show': => @show(true)
    )

  deactivate: ->
    @subscriptions.dispose()

  show: (isDir=false) ->
    requirePackages('find-and-replace').then ([find]) ->
      return unless find

      view = find.projectFindView
      editor = atom.workspace.getActiveTextEditor()

      selectedText = editor?.getSelectedText() or ''
      filePath = editor?.buffer.file?.path

      find.findPanel.hide()
      find.projectFindPanel.show()
      find.projectFindView.focusFindElement()

      if selectedText and selectedText.indexOf('\n') < 0
        if view.model.getFindOptions().useRegex
          selectedText = Util.escapeRegex(selectedText)
          view.findEditor.setText(selectedText)

      paths = ''
      if filePath
        if isDir
          paths = path.dirname(filePath)
          for projectPath in atom.project.getPaths()
            paths = paths
              .replace(projectPath, '')
              .replace(new RegExp('^' + path.sep), '')
          paths = path.join(paths, '**')
        else
          pattern = atom.config.get(
            'find-and-replace-same-type.patternExpression')

          ext = path.extname(path.basename(filePath)).replace(/^\./, '')
          if ext
            paths = pattern.replace '{ext}', ext

      view.pathsEditor.setText paths

      view.findEditor.focus()
      view.findEditor.getModel().selectAll()
