require 'busted'
require 'loxy'

describe("object override metatable method", function()

  it("handle override __tostring", function()
    local c = object({
      __tostring = function(self)
        return "overided"
      end
    })()
    assert.is.equal(tostring(c), 'overided')
  end)

  it("handle override __eq", function()
    local X
    local C = object({
      val = 0,
      __eq = function(f,s)
        return s.val == f.val
      end
    })

    c = C{val = 1}
    d = C{val = 1}
    e = C{val = 2}

    assert.is.equal(c,d)
    assert.is.not_equal(c,e)
  end)

end)
