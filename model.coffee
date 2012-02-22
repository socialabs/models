## Data model for client-side JS
# (c) 2011 Socialabs

Events = Backbone.Events

class EventedBase
    _.extend @::, Events

### Properties

class Field
    constructor: (@name, {@type, @validate}) ->

    getProperty: ->
        self = this
        (value, options={}) ->
            if arguments.length == 0
                if self.name of @changes
                    return @changes[self.name]
                else
                    return @data[self.name]

            if self.validate and not self.validate(value)
                @trigger 'error', "Invalid value for '#{self.name}': '#{value}'"
                return false
            @changes[self.name] = value

            @trigger "change:#{self.name}", this, value
            if not options.batch
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
                    throw ("Error: attempt to read " +
                        "non-readable property: '#{self.name}'")
                return self.get.call(this)

            if not self.set
                throw ("Error: attempt to change " +
                    "non-writable property: '#{self.name}'")
            self.set.call(this, value)

            @trigger "change:#{self.name}", this, value
            if not options.batch
                data = {}
                data[self.name] = value
                @trigger 'change', this, data

            this


class Relation
    constructor: (@type, @name, @model, @options) ->

    getProperty: ->
        self = this
        (value, options={}) ->
            if arguments.length == 0
                true


### Model

class Model extends EventedBase

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

    @_relation: (type, name, model, options) ->
        if typeof model == 'string'
            model = eval(model)
        @fields[name] = new Relation(type, name, model, options)
        @::[name] = @fields[name].getProperty()

    @oneToMany: (name, model, options) ->
        @_relation('oneToMany', name, model, options)

    @oneToOne: (name, model, options) ->
        @_relation('oneToOne', name, model, options)

    @manyToOne: (name, model, options) ->
        @_relation('manyToOne', name, model, options)

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
                @[key](value, batch: true)

        @trigger 'change', this, data
        this

    # Pending changes take over original data
    get: (name) ->
        @[name]()

    # Data which we had before changes
    previous: (name) ->
        field = @fields[name]
        @data[field.fieldName or name]

    save: (data, options={}) ->
        @set(data) if data

    # Utility
    toObject: ->
        _.extend({}, @data, @changes)


### Model set

class Set extends EventedBase
    constructor: (@model, @models=[]) ->

    # Underscore methods to implement on the Set
    methods = ['forEach', 'each', 'map', 'reduce', 'reduceRight', 'find',
        'detect', 'filter', 'select', 'reject', 'every', 'all', 'some', 'any',
        'include', 'contains', 'invoke', 'max', 'min', 'sortBy', 'sortedIndex',
        'toArray', 'size', 'first', 'rest', 'last', 'without', 'indexOf',
        'lastIndexOf', 'isEmpty', 'groupBy'];

    for method in methods
        @::[method] = ->
            _[method].apply(_, [@models].concat(_.toArray(arguments)))


### Backends

class EventBackend extends EventedBase

    create: (model) ->
        @trigger 'create', model.constructor, model.toObject()

    update: (model) ->
        @trigger 'update', model.constructor, _.extend({}, model.changes)

    delete: (model) ->
        @trigger 'delete', model.constructor, model.id()

    read: (model) ->
        throw 'Read not implemented'


class LocalStorageBackend extends EventedBase

    create: (model) ->
        @trigger 'create', model.constructor, model.toObject()

    update: (model) ->
        @trigger 'update', model.constructor, _.extend({}, model.changes)

    delete: (model) ->
        @trigger 'delete', model.constructor, model.id()

    read: (model) ->
        throw 'Read not implemented'
