require 'busted'
require 'loxy'

describe('Handle special case if attr set to nil',function()
  local C

  setup(function() 
    C = object({
      attr = 'attr'
    })
  end)

  before_each(function()
    -- check the original class is not modified
    assert.is.equal(C.attr, 'attr')
  end)

  it('handle implicit c-tor',function()
    local c = C{attr = nil}
    assert.is.equal(c.attr, 'attr')
  end)

  it('handle set by property',function()
    local c = C{attr = 'setted'}
    assert.is.equal(c.attr, 'setted')
    c.attr = nil
    assert.is.equal(c.attr, 'attr')
  end)

  it('handle explicit ctor',function()
    local D = object({
      attr = 'attr',
      __init = function(self, attr)
        self.attr = attr
      end,
    })
    local d = D(nil)
    assert.is.equal(d.attr, 'attr')
  end)

  it('handle in explicit ctor',function()
    local D = object({
      attr = 'attr',
      __init = function(self)
        self.attr = nil
      end,
    })
    local d = D()
    assert.is.equal(d.attr, 'attr')
  end)

  it('handle in explicit ctor, by nonexist table attr',function()
    local D = object({
      attr = 'attr',
      arr = false,
      __init = function(self, data)
        self.arr = {}
        self.attr = data.attr
      end,
    })
    local d = D({})
    assert.is.equal(d.attr, 'attr')
  end)
end)
