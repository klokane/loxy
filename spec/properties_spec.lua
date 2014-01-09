require 'busted'
require 'loxy'

describe("testing object syntax sugar behaviors", function()

  local CIRCLE, circle
  before_each(function()
    CIRCLE = object({
      radius = 0,
      getArea = function(self)
        return self.radius * 3.14
      end
    })
    circle = CIRCLE({ radius = 10 })
  end)

  describe("Testing props/getter/setter", function()
    it('should call method of object', function()
      assert.is.equal(circle:getArea(), 3.14 * 10)
    end)

    it('should return property', function()
      assert.is.equal(circle.radius, 10)
    end)

    it('should handle magic property via getter', function()
      assert.is.equal(circle.area, 3.14 * 10)
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


  describe("Testing setter && property functionality", function()
    local o
    before_each(function()
      o = object({
        x = 0,
        setX = function(self, x) self.x = x + 1 end,
      })({ x = 1 })
    end)

    it('setter is invoked while implicit init', function()
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

    it('allow bypass implicit ctor invocation, instead use agr as impl',function()
      local o = object({
        x = 0,
        setX = function(self, x) self.x = x + 1 end,
      })({ x = 1 },false)
      assert.is.equal(o.x,1)
      o:setX(3)
      assert.is.equal(o.x, 4)
      o.x = 5 
      assert.is.equal(o.x, 6)
    end)

  end)

  describe("Testing getter && property functionality", function()
    local o
    before_each(function()
      o = object({
        x = 0,
        getX = function(self) return self.x + 1 end,
      })({ x = 1 })
    end)

    it('direct call getter', function()
      assert.has.errors(function() o:getX() end)
    end)

    it('get througth property', function()
      assert.has.errors(function() return o.x end)
    end)
  end)

  --[[

  describe("Testing events functionality", function()
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
  --]]

  --[[
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
  --]]
  
end)
