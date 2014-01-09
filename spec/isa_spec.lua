require 'busted'
require 'loxy'

describe("querying object type througth is_a()", function()

  it("instance is type of class", function()
    local C = object({})

    local c = C()
    local d = C()

    assert.is.True(is_a(c,C))
    assert.is.True(is_a(d,C))
  end)

  it("is allowed to query any type", function()
    local C = object({})
    assert.is.False(is_a({},C))
    assert.is.False(is_a(nil,C))
    assert.is.False(is_a(true,C))
    assert.is.False(is_a(1,C))
  end)

  it("instance of inherited", function()
    local C = object({})
    local D = object(C,{})

    local c = C()
    local d = D()

    assert.is.False(is_a(d,C))
    assert.is.True(is_a(c,C))
    assert.is.False(is_a(d,C))
    assert.is.True(is_a(d,D))
  end)

  it("can ask as member", function()
    local C = object({})
    local c = C()

    assert.is.True(c:is_a(C))
  end)


end)
