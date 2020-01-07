_ = require 'lodash'
db = require './db'

class Model
  name: ''

  attributes: []

  constructor: ->
    @model = db.get @name

  addMiddleware: (mw) ->
    db.addMiddleware mw

  create: (ctx, next) ->
    try
      ctx.response.body = await @model.insert _.pick ctx.request.body, @attributes
      await next()
    catch err
      ctx.throw 500, err.toString()

  update: (ctx, next) ->
    try
      query = ctx.params.id
      update = $set: _.pick ctx.request.body, @attributes
      ctx.response.body = await @model.findOneAndUpdate query, update
      await next()
    catch err
      ctx.throw 500, err.toString()

  findOne: (ctx, next) ->
    try
      ctx.response.body = await @model.findOne ctx.params
      await next()
    catch err
      ctx.throw 500, err.toString()
    
  find: (ctx, next) ->
    try
      optsField = ['limit', 'skip', 'sort']
      opts = _.pick ctx.request.body, optsField
      opts = _.defaults opts, {limit: 30, skip: 0}
      query = _.omit ctx.request.body, optsField
      ctx.response.body = await @model.find query, opts
      await next()
    catch err
      ctx.throw 500, err.toString()

  destroy: (ctx, next) ->
    try
      ctx.response.body = await @model.findOneAndDelete ctx.params.id
      await next()
    catch err
      ctx.throw 500, err.toString()

  isAuthorized: (ctx, next) ->
    {user} = ctx.session
    {id} = ctx.params
    try
      app = await @model.findOne id
      if app?
        if app.createdBy == user._id
          await next()
        else
          ctx.status = 401
    catch err
      ctx.throw 500, err.toString()
 
  #return controller actions for the input method names
  actions: (names = ['create', 'findOne', 'find', 'update', 'destroy', 'isAuthorized']) ->
    reducer = (actions, action) =>
      actions[action] = (ctx, next) =>
        @[action] ctx, next
      actions
    names.reduce reducer, {}

module.exports = Model
