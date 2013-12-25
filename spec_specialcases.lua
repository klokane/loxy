require 'busted'
require 'object'

describe("object special cases", function()

  it("handle false attribute", function()
    local c = object({
      yes = true,
      no = false,
    })()
    assert.is.equal(c.yes, true)
    assert.is.equal(c.no, false)
  end)

--[[
  it("handle override __tostring", function()
    local c = object({
      __tostring = function(self)
        return "overided"
      end
    })()
    assert.is.equal(tostring(c), 'overided')
  end)
--]]

  it("c-tor should create own instance", function()
    local C = object({ a = 0 })

    local c1 = C()
    local c2 = C()

    c1.a = 1
    c2.a = 2

    assert.is.equal( C.a, 0)
    assert.is.equal(c1.a, 1)
    assert.is.equal(c2.a, 2)
  end)

  it("implicit c-tor should create own instance", function()
    local C = object({ a = 0 })

    local c1 = C({a = 1})
    local c2 = C{a = 2}

    assert.is.equal( C.a, 0)
    assert.is.equal(c1.a, 1)
    assert.is.equal(c2.a, 2)
  end)

  it("explicit c-tor should create own instance", function()
    local C = object({ a = 0, __init = function(self,a) self.a = a end })

    local c1 = C(1)
    local c2 = C(2)

    assert.is.equal( C.a, 0)
    assert.is.equal(c1.a, 1)
    assert.is.equal(c2.a, 2)
  end)

  local C
  it("testing #clone", function()
    C = object({
      a = 'none',
      clone = function(self)
        return C{ 
          a = self.a 
        }
      end,
    })

    assert.is.equal(C.a, 'none')

    o = C{a='origin'}
    assert.is.equal(o.a,'origin')
    assert.is.equal(C.a,'none')

    c = o:clone()
    assert.is.equal(o.a,'origin')
    assert.is.equal(c.a,'origin')
    assert.is.equal(C.a,'none')

    c.a = 'cloned'
    assert.is.equal(c.a,'cloned')
    assert.is.equal(o.a,'origin')
    assert.is.equal(C.a,'none')
  end)

end)
