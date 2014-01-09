require 'busted'
require 'loxy.signal'

describe('testing signal functionality', function()

 local s, v, f
 before_each(function()
    s = signal()
    v = 0
    f = function(val) v = val end
 end)

  it('should handle connect/emit', function()
    s:connect(f)
    assert.is.equal(v, 0)
    s:emit(3)
    assert.is.equal(v, 3)
  end)

  it('should handle closure', function()
    s:connect(function(x) v = x + 3 end)
    s:emit(3)
    assert.is.equal(v, 6)
  end)

  it('should handle multiple connections', function()
    local X = 0
    s:connect(f)
    s:connect(function(x) X = x end)

    s:emit(3)
    assert.is.equal(v, 3)
    assert.is.equal(X, 3)
  end)

end)

describe('testing preddefined marshallers functionality', function()

  it('"last" returns last value',function()
    local s = signal()
    s:connect(function() return 1 end)
    s:connect(function() return 2 end)
    s:connect(function() return 3 end)
    -- last invocation value is returned
    assert.is.equal(3, s())

    -- next emit return last value again
    assert.is.equal(3, s())

    -- add next callback
    s:connect(function() return 4 end)
    -- last value is now new callback
    assert.is.equal(4, s())
  end)

  it('"table" returns last value',function()
    local s = signal(marshaller.table)
    s:connect(function() return 1 end)
    s:connect(function() return 2 end)
    s:connect(function() return 3 end)
    assert.is.same({1,2,3}, s())

    s:connect(function() return 4 end)
    assert.is.same({1,2,3,4}, s())
  end)

end)
