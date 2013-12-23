require 'signal'

local print = function() end

local camelize = function(str)
    return str:gsub("^%l", string.upper)
end

local util = {
  toGetter = function(property)
    return 'get' .. camelize(property)
  end,

  toSetter = function(property)
    return 'set' .. camelize(property)
  end,

  toProperty = function(method)
    return method:gsub("^[sg]et",""):gsub("^%a", string.lower)
  end,

  isSetter = function(method)
    return method:match("^set.+")
  end,
}

local object_reflection = function(obj)
  return {
    obj = obj,
    hasProperty = function(self, property)
      return self.obj[property] ~= nil and type(self.obj[property]) ~= 'function'
    end,

    hasMethod = function(self, method)
      return self.obj[method] ~= nil and type(self.obj[method]) == 'function'
    end,

    hasGetter = function(self, property) 
      return self:hasMethod(util.toGetter(property))
    end,

    hasConstructor = function(self)
      return self.obj['init'] ~= nil and type(self.obj['init']) == 'function'
    end,
  }
end

local object_proxy = function(obj, parent)
  return {

    __index = function(table, index) 
      local proxy = getmetatable(table)
      local obj = proxy.obj
      local rx = object_reflection(obj)

      print("I", table, index, obj, type(obj[index]))
      if util.isSetter(index) and rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        print("S + P", index)
        return function(proxy,val) obj[index](obj,val) end
      elseif rx:hasMethod(index) or rx:hasProperty(index) then
        print("D", index)
        return obj[index]
      elseif not rx:hasProperty(index) and rx:hasGetter(index) then
        local getter = util.toGetter(index)
        print("P -> G", index, getter)
        return obj[getter](obj)
      elseif not rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        local property = util.toProperty(index)
        if util.isSetter(index) then
          print("S -> P", index, property)
          return function(proxy,val) obj[property] = val end
        else 
          print("G -> P", index, property)
          return function() return obj[property] end
        end
      elseif index == 'extensionMethod' then
          print("EXM", index, property)
          return function(name, fn) obj[name] = fn end
      elseif proxy.parent then -- try invoke parent 
        print("P", index, property)
        return proxy.parent[index]
      elseif index == 'init' then -- asking for nonexisting c-tor
        print("C", index, property)
        return nil
      end
      error("request nonexisting attribute: "..index)
    end,

    __newindex = function(table, index, value)
      local proxy = getmetatable(table)
      local obj = proxy.obj
      local rx = object_reflection(obj)

      --print("NI", table, index, value, obj)
      if rx:hasMethod(util.toSetter(index)) then
        local setter = util.toSetter(index)
        obj[setter](obj,value)
      elseif rx:hasProperty(index) then
        obj[index] = value
      end
    end,

    __call = function(self, ...)
      if #arg >= 1 and self['init'] then
        self:init(unpack(arg))
      elseif #arg == 1 and type(arg[1]) == 'table' then
        for k,v in pairs(arg[1]) do
          self[k] = v
        end
      end
     
      return self
    end,

    __tostring = function(self)
      local obj = getmetatable(self).obj
      if obj['__tostring'] then
        return obj:__tostring()
      end
      return tostring(obj)
    end,


    obj = obj,
    parent = parent,
  }
end

object = function(parent, obj)
  if not obj then
   obj = parent
   parent = nil
  end

  obj = obj or {}

  o = setmetatable({}, object_proxy(obj, parent))
  return o
end

