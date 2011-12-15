class Field
  constructor: (@name, {@type, @validate}) ->

  getProperty: ->
    self = this
    (value, options={}) ->
      if arguments.length == 0
        return @get(self.name)
      if self.validate and not self.validate(value)
        @trigger 'error', "Invalid value for '#{self.name}': '#{value}'"
        return false
      @changes[self.name] = value

      @trigger "change:#{self.name}", this, value
      if not options.fromSet
        data = {}
        data[self.name] = value
        @trigger 'change', this, data

      this


class Accessor
  constructor: (@name, {@get, @set}) ->

  getProperty: ->
    self = this
    (value, options={}) ->
      if arguments.length == 0
        if not self.get
          throw "Error: attempt to read non-readable property: '#{self.name}'"
        return self.get.call(this)
      if not self.set
        throw "Error: attempt to change non-writable property: '#{self.name}'"
      self.set.call(this, value)

      @trigger "change:#{self.name}", this, value
      if not options.fromSet
        data = {}
        data[self.name] = value
        @trigger 'change', this, data

      this


class Model
  _.extend @::, Backbone.Events

  constructor: (data, options={}) ->
    @data = _.extend({}, data)
    @changes = {}

    if options.backend
      @backend = options.backend

    if @initialize
      @initialize data, options

  # Model definition layer

  @field: (name, options) ->
    if not @fields
      @fields = {}

    @fields[name] = new Field(name, options)
    @::[name] = @fields[name].getProperty()

  @accessor: (name, options) ->
    if not @fields
      @fields = {}

    @fields[name] = new Accessor(name, options)
    @::[name] = @fields[name].getProperty()

  # Instance methods

  set: (data, options={}) ->
    this unless data

    for key, value of data
      if key not of @constructor.fields
        throw "Unknown field name: '#{key}'"
      else if (@constructor.fields[key].constructor == Field and
        _.isEqual(@data[key], value))
          # remove changes if we have any
          delete @changes[key]
      else
        @[key](value, fromSet: true)

    @trigger 'change', this, data
    this

  # Pending changes take over original data
  get: (name) ->
    if name of @changes
      @changes[name]
    else
      @data[name]

  # Data which we had before changes
  previous: (name) ->
    @ata[name]

  toObject: ->
    _.extend({}, @data, @changes)


class EventBackend
  _.extend @::, Backbone.Events

  create: (model) ->
    @trigger 'create', model.constructor, model.toObject()

  update: (model) ->
    @trigger 'update', model.constructor, _.extend({}, model.changes)

  delete: (model) ->
    @trigger 'delete', model.constructor, model.id()

  read: (model) ->
    throw 'Read not implemented'
