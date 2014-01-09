require 'busted'
require 'loxy'

--tostring = require 'ml'.tstring
describe("object basic concepts", function()
  it('should handle inheritance concept', function()

    local shape = object({ -- create obj w/o inheritance
      name = 'shape',
      draw = function(self) return 'draw '..self.name end
    })

    local s = shape() -- create shape instance
    assert.is.equal(s:draw(), 'draw shape')

    local circle = object(shape,{ -- inherit from shape
      name = 'circle',
      radius = 0,
      getArea = function(self)
        return self.radius * 3.14
      end
    })

    local c = circle{ radius = 10 } -- create instance of cicle
    assert.is.equal(c:draw(), 'draw circle') -- try to invoke parent
    assert.is.equal(c.area, 10*3.14)

    local filledCircle = object(circle,{ -- inherit from cicrle, but override draw
      fill = 'none',
      draw = function(self) return string.format("draw %s %s", self.fill, self.name) end,
    })
    local fc = filledCircle{fill = 'red'}
    assert.is.equal(fc:draw(), 'draw red circle') -- invoke overrided draw()

  end)

  it('should handle constructor concept', function()

    local named = object({ -- create obj w/o inheritance
      name = 'name',
      setName = function(self,val)
        self.name = "test "..val
      end
    })

    local n1 = named()
    assert.is.equal(n1:getName(), 'name')

    local n2 = named({ name = 'n2'})
    assert.is.equal(n2:getName(), 'test n2')

    local namedInit = object({
      name = 'none',
      init = function(self, name)
        self.name = name
      end,
    })

    local ni1 = namedInit('ctor')
    assert.is.equal(ni1.name, 'ctor')

    local ni2 = namedInit({ name = 'xx'}) -- do not invoke init via table
    assert.is.same(ni2.name, { name = 'xx'} )

  end)
end)

describe("testing object syntax sugar behaviors", function()

  local circle
  before_each(function()
    circle = object({
      radius = 0,
      getArea = function(self)
        return self.radius * 3.14
      end
    })({ radius = 10 })
  end)

  describe("Testing props/getter/setter", function()


    it('should call method of object', function()
      assert.is.equal(circle:getArea(), 3.14 * 10)
    end)
 
    it('should handle magic property via getter', function()
      assert.is.equal(circle.area, 3.14 * 10)
    end)

    it('should return property', function()
      assert.is.equal(circle.radius, 10)
    end)

    it('should handle magic getter for existing property', function()
      assert.is.equal(circle:getRadius(), 10)
    end)

    it('should allow set property', function()
      circle.radius = 20
      assert.is.equal(circle:getRadius(), 20)
    end)
  
    it('should allow magic setter for existing property', function()
      circle:setRadius(20)
      assert.is.equal(circle:getRadius(), 20)
      assert.is.equal(circle.radius, 20)
    end)

  end)

  describe("Testing handle error for nonexisting props/methods", function()
    it('should throw error while ask nonexisting property', function()
      assert.has.errors(function() return circle.diameter end)
    end)

    it('should throw error while call nonexisting method', function()
      assert.has.errors(function() return circle:visible() end)
    end)
  end)


  describe("Testing setter functionality", function()
    local o
    before_each(function()
      o = object({
        x = 2,
        setX = function(self, x) self.x = x + 1 end,
      })()
    end)

    it('do not invoke setter while init', function()
      assert.is.equal(o.x,2)
    end)

    it('setter should modify value of property', function()
      o:setX(3)
      assert.is.equal(o.x, 4)
    end)

    it('set property should invoke setter', function()
      o.x = 5 
      assert.is.equal(o.x, 6)
    end)

  end)

  describe("Testing event functionality", function()
    local o
    before_each(function()
      o = object({
        onChange = signal.new(),
        x = 2,
        setX = function(self, x) 
          self.onChange(self, self.x, x) 
          self.x = x
        end,
      })()
    end)

    it('should allow connect/emit signal', function()
      local g = 0
      o.onChange:connect(function(obj, old, new) 
        assert.is.equal(old, 2)
        g = new 
      end)
      assert.is.equal(g, 0)
      o:setX(4)
      assert.is.equal(o.x, 4)
      assert.is.equal(g, 4)
    end)

    it('should allow connect/emit signal', function()
      local c = {
        new = function(x)
          return {
            x = x,
            set = function(self, obj, old, new)
              self.x = new
            end,
          }
        end
      }

      v = c.new(3)
      assert.is.equal(v.x, 3)
      o.onChange:connect(v, 'set')
      o:setX(4)
      assert.is.equal(o.x, 4)
      assert.is.equal(v.x, 4)
    end)

  end)

  describe("Testing extension method", function()
    local circle
    before_each(function()
      circle = object({
        radius = 10,
        getArea = function(self)
          return self.radius * 3.14
        end
      })()
    end)

    it('support extension method', function()
      circle.extensionMethod('getCircumfence', function(self) return self.radius * 2 * 3.14 end)
      assert.is.equal(circle:getCircumfence(), 10*2*3.14)
    end)

    it('support extension with params', function()
      local val
      circle.extensionMethod('invoke', function(self, a, b) val = a + b end)
      circle:invoke(2,3)
      assert.is.equal(val, 2 + 3)
    end)

  end)
  
end)
