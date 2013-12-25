require 'busted'
require 'object'

describe("object inheritance concepts", function()

  it('write attribute must not change other instances or class behavior', function()
    local C = object({ a = 0 })
    local c1 = C()
    c1.a = 1
    local c2 = C()
    c2.a = 2

    assert.is.equal( C.a,0)
    assert.is.equal(c1.a,1)
    assert.is.equal(c2.a,2)
  end)

  it('write inherited or overrided attribute must not change other instances or class behavior', function()
    local B = object({ a = 0 })
    local C = object(B,{})
    local D = object(B,{ a = 3})

    local c1 = C()
    c1.a = 1
    local c2 = C()
    c2.a = 2

    local d1 = D()
    local d2 = D()
    d2.a = 5

    assert.is.equal( B.a,0)
    assert.is.equal( C.a,0)
    assert.is.equal( D.a,3)

    assert.is.equal(c1.a,1)
    assert.is.equal(c2.a,2)
    assert.is.equal(d1.a,3)
    assert.is.equal(d2.a,5)
  end)

  it('should handle inheritance concept', function()
    local shape = object({ -- create obj w/o inheritance
      name = 'shape',
      draw = function(self) return 'draw '..self.name end
    })

    local s = shape() -- create shape instance
    assert.is.equal(shape:draw(), 'draw shape')
    s.name = 'shape instance'
    assert.is.equal(s:draw(), 'draw shape instance')

    local circle = object(shape,{ -- inherit from shape
      name = 'circle',
      radius = 0,
      getArea = function(self)
        return self.radius * 3.14
      end
    })

    local c = circle() -- create instance
    c.radius = 10      -- set instance
    assert.has.errors(function() c.radiator = 10 end)
    assert.is.equal(circle.radius, 0) -- check that class attr is not touched
    assert.is.equal(c.radius, 10)     -- check that instance has setted attr
    assert.is.equal(c:getArea(), 10*3.14) -- check class is not changed
    assert.is.equal(c:draw(), 'draw circle') -- try to invoke parent

    assert.is.equal(s:draw(), 'draw shape instance')
    assert.is.equal(shape:draw(), 'draw shape')

    local filledCircle = object(circle,{ -- inherit from cicrle, but override draw
      fill = 'none',
      draw = function(self) return string.format("draw %s %s", self.fill, self.name) end,
    })
    local fc = filledCircle()
    fc.fill = 'red'
    assert.is.equal(fc:draw(), 'draw red circle') -- invoke overrided draw()
    assert.is.equal(filledCircle:draw(), 'draw none circle') -- invoke overrided draw()

  end)

  it('has default construction via table', function()
    local C = object({ a = 0 })
    local c1 = C{ a = 1 }
    local c2 = C({ a = 2 })

    local D = object(C,{ a = 3})
    local d1 = C{ a = 4 }
    local d2 = C({ a = 5 })

    assert.is.equal( C.a,0)
    assert.is.equal(c1.a,1)
    assert.is.equal(c2.a,2)

    assert.is.equal( D.a,3)
    assert.is.equal(d1.a,4)
    assert.is.equal(d2.a,5)
  end)

  it('has explicit construction via __init', function()
    local X
    local C = object({ 
      a = 1, 
      __init = function(self, val) 
        X = val
      end 
    })

    local c = C(3)
    assert.is.equal(X, 3)

    local d = C({ a = 3 })
    assert.is.same(X, { a = 3 })
  end)

  it('should throw on try c-tor invocation on instance', function()
    local C = object({ a = 0, })

    local c = C(3)
    assert.has.errors(function() c(4) end)

  end)
end)

