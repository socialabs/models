class Todo extends Model
  @field 'text',
    type: 'string'
  @accessor 'moretext',
    get: -> @text() + ' more...'
    set: (value) -> @text(value.replace(/\ *more...$/, ''))

  initialize: ->
    console.log 'test'
    @bind 'all', ->
      console.log arguments


class User extends Model
  @field 'name', type: 'string'


t = new Todo(text: 'shit')
console.log t.text(), t.text('crap'), t.text()
console.log t.moretext()
t.set(moretext: 'qwehehe more...')
console.log t.text()
