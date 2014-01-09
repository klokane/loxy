require 'busted'
require 'loxy.callback'

describe('testing callback functionality', function()

  it('should handle direct function', function()
    local val = 0
    cb = callback(function(v) val = v end)
    cb:invoke(3)
    assert.is.equal(val, 3)
  end)

  it('should handle mt __call invoke', function()
    local val = 0
    cb = callback(setmetatable({}, {__call = function(t, v) val = v end}))
    cb:invoke(4)
    assert.is.equal(val, 4)
  end)

  it('should handle table + function as object invocation', function()
    local c = {
      new = function(x)
        return {
          x = x,
          set = function(self, v) self.x = v end,
        }
      end
    }
    o = c.new(5)
    assert.is.equal(o.x, 5)

    cb = callback(o, o.set)
    cb:invoke(8)
    assert.is.equal(o.x, 8)

    cb = callback(o.set, o)
    cb:invoke(9)
    assert.is.equal(o.x, 9)

    cb = callback(o, 'set')
    cb:invoke(10)
    assert.is.equal(o.x, 10)

    cb = callback('set', o)
    cb:invoke(11)
    assert.is.equal(o.x, 11)
  end)

  it('should handle syntax sugar invoke', function()
    local val = 0
    cb = callback(function(v) val = v end)
    cb(3)
    assert.is.equal(val, 3)
  end)

end)

