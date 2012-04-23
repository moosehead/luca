Sandbox.views.Editor = Luca.View.extend
  name: "editor"
  id: "editor_container"
  autoBindEventHandlers: true

  beforeRender: ()->
    _.bindAll @, "onChange"
    $(@el).append("<div id='coffee-script-editor' />")

  render: ()->
    Luca.View::render.apply(@, arguments)
    @

  afterRender: ()->
    @setupEditor()

  getSelection: ()->
    @editor.getSession().doc.getTextRange( @editor.getSelectionRange() );

  setupEditor: ()->
    @editor = ace.edit("coffee-script-editor")
    @editor.setTheme "ace/theme/monokai"
    @editor.session.setMode("ace/mode/coffee")
    @editor.setShowPrintMargin false
    @editor.getSession().setUseWrapMode(true);
    @editor.getSession().on('change', @onChange)
    @editor

  canvas: _.memoize ()->
    Luca.cache("canvas")

  onChange: _.idleShort ()->
    try
      code = @editor.session.getValue()
      @newCompiled = CoffeeScript.compile(code,bare:true)

      if @newCompiled isnt @oldCompiled
        @canvas().run( @newCompiled )
        @oldCompiled = @newCompiled

    catch error
      false

