#### Luca Base View

# The Luca.View class adds some very commonly used patterns
# and functionality to the stock Backbone.View class. Features
# such as auto event binding, the facilitation of deferred rendering
# against a Backbone.Model or Backbone.Collection reset event, Caching
# views into a global Component Registry, and more.
_.def("Luca.View").extends("Backbone.View").with
  applyStyles: (styles={})->
    for setting, value  of styles
      @$el.css(setting,value)

    @

  debug: ()->
    return unless @debugMode or window.LucaDebugMode?
    console.log [(@name || @cid),message] for message in arguments

  trigger: ()->
    if Luca.enableGlobalObserver and @observeEvents is true
      Luca.ViewObserver ||= new Luca.Observer(type:"view")
      Luca.ViewObserver.relay @, arguments

    Backbone.View.prototype.trigger.apply @, arguments

  hooks:[
    "after:initialize"
    "before:render"
    "after:render"
    "first:activation"
    "activation"
    "deactivation"
  ]

  initialize: (@options={})->

    _.extend @, @options

    @cid = _.uniqueId(@name) if @name?

    #### View Caching
    #
    # Luca.View(s) which get created get stored in a global cache by their
    # component id.  This allows us to re-use views when it makes sense
    Luca.cache( @cid, @ )

    unique = _( Luca.View.prototype.hooks.concat( @hooks ) ).uniq()

    @setupHooks( unique )

    if @autoBindEventHandlers is true
      @bindAllEventHandlers()


    @trigger "after:initialize", @

    @registerCollectionEvents()

    if @bodyTemplate
      @$html( Luca.template(@bodyTemplate, @) )

    @delegateEvents()


  #### JQuery / DOM Selector Helpers
  $bodyEl: ()->
    element = @bodyTagName || "div"
    className = @bodyClassName || "view-body"

    @bodyEl = "#{ element }.#{ className }"

    bodyEl = @$(@bodyEl)

    return bodyEl if bodyEl.length > 0

    # if we've been configured to have one, and it doesn't exist
    # then we should append it to ourselves
    if bodyEl.length is 0 and (@bodyClassName? || @bodyTagName?)
      bodyEl = @make(element,class:className)
      $(@el).append( bodyEl )
      return @$(@bodyEl)


    $(@el)

  $template: (template, variables={})->
    @$html( Luca.template(template,variables) )

  $html: (content)->
    @$bodyEl().html( content )

  $append: (content)->
   @$bodyEl().append(content)

  #### Containers
  #
  # Luca is heavily reliant on the concept of Container views.  Views which
  # contain other views and handle inter-component communication between the
  # component views.  The default render() operation consists of building the
  # view's content, and then attaching that view to its container.
  #
  # 99% of the time this would happen automatically
  $attach: ()->
    @$container().append( @el )

  $container: ()->
    $(@container)

  #### Hooks or Auto Event Binding
  #
  # views which inherit from Luca.View can define hooks
  # or events which can be emitted from them.  Automatically,
  # any functions on the view which are named according to the
  # convention will automatically get run.
  #
  # by default, all Luca.View classes come with the following:
  #
  # before:render     : beforeRender()
  # after:render      : afterRender()
  # after:initialize  : afterInitialize()
  # first:activation  : firstActivation()
  setupHooks: (set)->
    set ||= @hooks

    _(set).each (eventId)=>
      fn = Luca.util.hook( eventId )

      callback = ()=>
        @[fn]?.apply @, arguments

      callback = _.once(callback) if eventId?.match(/once:/)

      @bind eventId, callback


  #### Luca.Collection and Luca.CollectionManager integration

  # under the hood, this will find your collection manager using
  # Luca.CollectionManager.get, which is a function that returns
  # the first instance of the CollectionManager class ever created.
  #
  # if you want to use more than one collection manager, over ride this
  # function in your views with your own logic
  getCollectionManager: ()->
    @collectionManager || Luca.CollectionManager.get?.call()

  ##### Collection Events
  #
  # By defining a hash of collectionEvents in the form of
  #
  # "books add" : "onBookAdd"
  #
  # the Luca.View will bind to the collection found in the
  # collectionManager with that key, and bind to that event.
  # a property of @booksCollection will be created on the view,
  # and the "add" event will trigger "onBookAdd"
  #
  # you may also specify a function directly.  this
  #
  registerCollectionEvents: ()->
    manager = @getCollectionManager()

    _( @collectionEvents ).each (handler, signature)=>
      [key,event] = signature.split(" ")

      collection = @["#{ key }Collection"] = manager.getOrCreate( key )

      if !collection
        throw "Could not find collection specified by #{ key }"

      if _.isString(handler)
        handler = @[handler]

      unless _.isFunction(handler)
        throw "invalid collectionEvents configuration"

      try
        collection.bind(event, handler)
      catch e
        console.log "Error Binding To Collection in registerCollectionEvents", @
        throw e

  registerEvent: (selector, handler)->
    @events ||= {}
    @events[ selector ] = handler
    @delegateEvents()

  bindAllEventHandlers: ()->
    _( @events ).each (handler,event)=>
      if _.isString(handler)
        _.bindAll @, handler

  # which properties of this view instance are backbone views
  viewProperties: ()->
    propertyValues = _( @ ).values()

    properties = _( propertyValues ).select (v)->
      Luca.isBackboneView(v)

    components = _( @components ).select (v)-> Luca.isBackboneView(v)

    _([components,properties]).flatten()

  # which properties of this view instance are backbone collections
  collectionProperties: ()->
    propertyValues = _( @ ).values()
    _( propertyValues ).select (v)->
      Luca.isBackboneCollection(v)

  definitionClass: ()->
    Luca.util.resolve(@displayName, window)?.prototype
  # refreshCode happens whenever the Luca.Framework extension
  # system is run after there are running instances of a given component

  # in the context of views, what this means is that each eventHandler which
  # is bound to a specific object via _.bind or _.bindAll, or autoBindEventHandlers
  # is refreshed with the prototype method of the component that it inherits from,
  # and then delegateEvents is called to refresh any of the updated event handlers

  # in addition to this, all properties of the instance of a given view which are
  # also backbone views will have the same process run against them
  refreshCode: ()->
    view = @

    _( @eventHandlerProperties() ).each (prop)->
      view[ prop ] = view.definitionClass()[prop]

    if @autoBindEventHandlers is true
      @bindAllEventHandlers()

    @delegateEvents()

  eventHandlerProperties: ()->
    handlerIds = _( @events ).values()
    _( handlerIds ).select (v)->
      _.isString(v)

  eventHandlerFunctions: ()->
    handlerIds = _( @events ).values()
    _( handlerIds ).map (handlerId)=>
      if _.isFunction(handlerId) then handlerId else @[handlerId]

Luca.View.originalExtend = Backbone.View.extend

customizeRender = (definition)->
  #### Rendering
  #
  # Our base view class wraps the defined render() method
  # of the views which inherit from it, and does things like
  # trigger the before and after render events automatically.
  # In addition, if the view has a deferrable property on it
  # then it will make sure that the render method doesn't get called
  # until.

  _base = definition.render

  _base ||= Luca.View::$attach

  definition.render = ()->

    # if a view has a deferrable property set

    if @deferrable and Luca.supportsBackboneEvents( @deferrable )
      deferredRender = _.once ()=>
        _base.apply(@, arguments)
        @trigger "after:render", @

      (@deferrable_target || @deferrable).bind (@deferrable_event||"reset"), deferredRender

      @trigger "before:render", @

      if !@deferrable_trigger
        @deferrable[ (@deferrable_method||"fetch") ]?()
      else
        fn = _.once ()=> @deferrable[ (@deferrable_method||"fetch") ]?()
        (@deferrable_target || @ ).bind(@deferrable_trigger, fn)

      return @

    else
      @trigger "before:render", @
      _base.apply(@, arguments)
      @trigger "after:render", @

      return @

  definition

# By overriding Backbone.View.extend we are able to intercept
# some method definitions and add special behavior around them
# mostly related to render()
Luca.View.extend = (definition)->
  definition = customizeRender( definition )
  Luca.View.originalExtend.call(@, definition)

