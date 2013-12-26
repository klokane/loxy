require 'busted'
require 'signal'

describe('testing signal functionality', function()

 local s, v, f
 before_each(function()
    s = signal.new()
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
