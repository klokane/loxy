require 'signal'

local print = function() end

local ctor = '__init'

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
  return { -- todo cache results
    obj = obj,
    hasProperty = function(self, property)
      local e,p = pcall(function() return self.obj[property] end)
      return e and p ~= nil and type(p) ~= 'function'
    end,

    hasMethod = function(self, method)
      local e,m = pcall(function() return self.obj[method] end)
      return e and m ~= nil and type(m) == 'function'
    end,

    hasGetter = function(self, property) 
      return self:hasMethod(util.toGetter(property))
    end,

    hasSetter = function(self, property) 
      return self:hasMethod(util.toSetter(property))
    end,

    hasConstructor = function(self)
      return rawget(self.obj,ctor) ~= nil
      --return self:hasMethod(ctor)
    end,
  }
end

--[[
 TODO:
 * :is_a()
 * access parent methods
 * check extension method
--]]

local object_manipulators = function(instance)
  local proxy = getmetatable(instance)
  local impl = proxy.impl
  local rx = object_reflection(impl)

  if not proxy or not impl or not rx then
    error('Is not proxy object: '..tostring(instance))
  end

  return proxy, impl, rx
end


local object_proxy = function(impl, parent)
  local parent_mt = getmetatable(parent)
  if getmetatable(impl) then error("implementation has already parent: "..impl) end
  if parent_mt then setmetatable(impl, { __index = parent_mt.impl }) end
  return {
    __index = function(table, index) 
      local proxy, impl, rx = object_manipulators(table) 
      print("R:", table, proxy, impl, index, type(impl[index]))
      --print(index, rx:hasProperty(index), rx:hasMethod(index), rx:hasGetter(index))
      if util.isSetter(index) and rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        print("S + P", index)
        return function(proxy,val) impl[index](impl,val) end
      elseif rx:hasGetter(index) and rx:hasProperty(index) then 
        print("G + P")
        error('undefined behavior, there is defined both property and getter for: '.. index)
      elseif rx:hasProperty(index) or rx:hasMethod(index) then -- get direct property/method
        print("D")
        return impl[index]
      elseif not rx:hasProperty(index) and rx:hasGetter(index) then
        local getter = util.toGetter(index)
        print("P -> G", index, getter)
        return impl[getter](impl)
      elseif not rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        local property = util.toProperty(index)
        if util.isSetter(index) then
          print("S -> P", index, property)
          return function(proxy,val) impl[property] = val end
        else 
          print("G -> P", index, property)
          return function() return impl[property] end
        end
      end
      error("read unknown attribute: "..index)

--[[

      print("I", table, index, impl, type(impl[index]))
      if util.isSetter(index) and rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        print("S + P", index)
        return function(proxy,val) impl[index](impl,val) end
      elseif rx:hasMethod(index) or rx:hasProperty(index) then
        print("D", index)
        return impl[index]
      elseif not rx:hasProperty(index) and rx:hasGetter(index) then
        local getter = util.toGetter(index)
        print("P -> G", index, getter)
        return impl[getter](impl)
      elseif not rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        local property = util.toProperty(index)
        if util.isSetter(index) then
          print("S -> P", index, property)
          return function(proxy,val) impl[property] = val end
        else 
          print("G -> P", index, property)
          return function() return impl[property] end
        end
      elseif index == 'extensionMethod' then
          print("EXM", index, property)
          return function(name, fn) impl[name] = fn end
      elseif proxy.parent then -- try invoke parent 
        print("P", index, property)
        return proxy.parent[index]
      elseif index == '__init' then -- asking for nonexisting c-tor
        print("C", index, property)
        return nil
      end
      error("request nonexisting attribute: "..index)
--]]      
    end,

    __newindex = function(table, index, value)
      local proxy, impl, rx = object_manipulators(table) 
      print("W:", table, proxy, impl, index, type(impl[index]), value)
      if rx:hasSetter(index) then
        print("S")
        local setter = util.toSetter(index)
        impl[setter](impl,value)
        return
      elseif impl[index] then
        print("D")
        impl[index] = value
        return 
      end
      error("write unknown attribute: "..index)
    end,

    __call = function(class, ...)
      local instance = object(class,{})
      local c_mt = getmetatable(class)
      local c = c_mt.impl[ctor]
      if c then
        c(instance, unpack(arg))
      elseif #arg == 1 and type(arg[1]) == 'table' then
        for k,v in pairs(arg[1]) do
          instance[k] = v
        end
      end

      -- disable c-tor
      getmetatable(instance).__call = nil --function() error('call constructor on instance') end

      print("I:",class, instance, ">", arg)

      return instance
    end,

--[[    
    __tostring = function(self)
      local impl = getmetatable(self).impl
      if impl['__tostring'] then
        return impl:__tostring()
      end
      return tostring(impl)
    end,
--]]

    impl = impl,
  }
end

--[[
  Class implementation:

  <instance>: - empty table, behavior is based on <proxy>
    +-mt.__(new)index -> <proxy>
    |                  +- <impl> (raw class as wriiten by user)
    |                       +-mt.__index - <parent impl> (w/o proxy)
    |
    +-mt.__call -> <c-tor> 
                      - implicit via table (copy key/value into instance)
                      - explicit via __init method
                      - on create object instance is __call se to nil 
                        to avoid invoke c-tor on object instance

--]]

object = function(parent, impl)
  if not impl then
   impl = parent
   parent = nil
  end

  impl = impl or {}

  local inst = setmetatable({}, object_proxy(impl, parent))
  print("C:",impl,inst,getmetatable(o), parent)
  return inst
end

