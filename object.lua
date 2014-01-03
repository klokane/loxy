require 'signal'

local ctor = '__init'
local overridable_metamethods = { 
  '__tostring', '__concat',
  '__add', '__mul', '__sub', '__div', '__unm', '__pow',
  '__eq', '__lt', '__le',
}

local print = function() end

local s_upper = string.upper
local s_lower = string.lower
local s_gsub  = string.gsub
local s_match = string.match

local function memoize (f)
  local mem = {}
  setmetatable(mem, {__mode = "kv"})
  return function (x)
    local r = mem[x]
    if r == nil then
      r = f(x)
      mem[x] = r
    end
    return r
  end
end


local camelize = function(str)
    return s_gsub(str,"^%l", s_upper)
end

camelize = memoize(camelize)

local util = {
  toGetter = function(property)
    return 'get' .. camelize(property)
  end,

  toSetter = function(property)
    return 'set' .. camelize(property)
  end,

  toProperty = function(method)
    return s_gsub(s_gsub(method,"^[sg]et",""),"^%a", s_lower)
  end,

  isSetter = function(method)
    return s_match(method,"^set.+")
  end,
}

local object_reflection = function(obj)
  return { -- todo cache results
    obj = obj,

    has = function(self, index)
      return self.obj[index] ~= nil
    end,

    hasProperty = function(self, property)
      --local e,p = pcall(function() return self.obj[property] end)
      --return e and p ~= nil and type(p) ~= 'function'
      local p = self.obj[property]
      return p ~= nil and type(p) ~= 'function'
    end,

    hasMethod = function(self, method)
      --local e,m = pcall(function() return self.obj[method] end)
      --return e and m ~= nil and type(m) == 'function'
      local m = self.obj[method]
      return m ~= nil and type(m) == 'function'
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

local object_manipulators = function(instance, strict)
  if strict == nil then strict = true end

  local proxy = getmetatable(instance)
  local impl = proxy and proxy.impl or nil
  local rx = proxy and proxy.reflection or nil

  if strict and (not proxy or not impl or not rx) then
    error('Is not proxy object: '..tostring(instance))
  end

  return proxy, impl, rx
end

    local M__newindex = function(instance, index, value)
      local proxy, impl, rx = object_manipulators(instance) 
      --print("W:", instance, proxy, impl, index, type(impl[index]), value)
      if rx:hasSetter(index) then
        --print("S")
        local setter = util.toSetter(index)
        impl[setter](impl,value)
        return
      elseif impl[index] ~= nil then -- get direct property/method
        --print("D")
        impl[index] = value
        return 
      end
      error("write unknown attribute: "..index)
    end

    local M__index = function(instance, attr) 
      --local proxy, impl, rx = object_manipulators(instance) 
      local proxy = getmetatable(instance)
      local impl = proxy and proxy.impl or nil
      local rx = proxy and proxy.reflection or nil

      local index = impl[attr]
      print("R:", instance, proxy, impl, attr, type(impl[attr]))

      if type(index) == 'function' then -- it is direct method call (setter include)
        return function(self,...) return index(impl , ...)  end
      elseif index ~= nil then -- it is property
        return impl[index]
      else -- no method, no property look for other solution
      end
--[[

      --local hm,hp = rx:hasMethod(index), rx:hasProperty(index)

      --print("R:", instance, proxy, impl, index, type(impl[index]))
      ----print(index, rx:hasProperty(index), rx:hasMethod(index), rx:hasGetter(index))
      if util.isSetter(index) and rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        --print("S + P", index)
        return function(instance,val) impl[index](impl,val) end
      elseif rx:hasGetter(index) and rx:hasProperty(index) then 
        --print("G + P")
        error('undefined behavior, there is defined both property and getter for: '.. index)
      elseif rx:hasProperty(index) or rx:hasMethod(index) then -- get direct property/method
        --print("D")
        return impl[index]
      elseif not rx:hasProperty(index) and rx:hasGetter(index) then
        local getter = util.toGetter(index)
        --print("P -> G", index, getter)
        return impl[getter](impl)
      elseif not rx:hasMethod(index) and rx:hasProperty(util.toProperty(index)) then
        local property = util.toProperty(index)
        if util.isSetter(index) then
          --print("S -> P", index, property)
          return function(instance,val) impl[property] = val end
        else 
          --print("G -> P", index, property)
          return function() return impl[property] end
        end
      elseif index == 'is_a' then
        return function(instance,class) return is_a(instance, class) end
      end
--]]
      error("read unknown attribute: "..attr)
    end


local object_proxy = function(impl, parent)
  -- error if impl has mt to avoid strange behavior
  if getmetatable(impl) then error("implementation has already parent: " .. impl) end
  -- impl inheritance througth mt._index
  local parent_mt = getmetatable(parent)
  if parent_mt then setmetatable(impl, { __index = parent_mt.impl }) end

  local proxy = {

    __index = function(instance, attr) 
      local proxy = getmetatable(instance)
      local impl = proxy.impl
      local rx = proxy.reflection

      local index = impl[attr]

      print("R:", instance, impl, attr, type(index))

      if type(index) == 'function' then -- it is direct method call (setter include)
        print("DF") -- we must return closure, we must send impl eas 'self' instead of instance
        return function(self,...) return index(impl , ...)  end
      elseif index ~= nil then -- it is property
        print("DP")
        return index
      else -- no method, no property look for other solution
        print("O")
      end
      error("read unknown attribute: "..attr)
    end,

    __newindex = function(instance, attr, value) 
      local proxy = getmetatable(instance)
      local impl = proxy.impl
      local rx = proxy.reflection

      local index = impl[attr]
      if index ~= nil then
        impl[attr] = value
        return
      end

      --print("W:", instance, impl, attr, type(index), value)
      --local setterName = util.toSetter(attr)
      --local setter = impl[setterName]

      --if setter ~= nil then
      --  setter(impl,value)
      --  return
      --elseif index ~= nil then
      --  index = value
      --  return
      --end

      error("write unknown attribute: "..attr)
    end,

    __call = function(parent, ...)
      local impl
      local hasInit = getmetatable(parent)['impl']['__init'] ~= nil
      if not hasInit and #arg == 1 and type(arg[1]) == 'table' then
        impl = arg[1]
      else
        impl = {}
      end

      instance = object(parent, impl)

      if hasInit then -- explicit c-tor
        parent['__init'](instance, unpack(arg))
      end

      -- disable c-tor for instance
      getmetatable(instance).__call = nil
      
      print("I:",parent, "=>", instance)
      return instance

 --[[
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

      local i_mt = getmetatable(instance)
      local impl = getmetatable(instance).impl

      -- disable c-tor
      i_mt.__call = nil --function() error('call constructor on instance') end
      -- override metamethods
      for _,method in pairs(overridable_metamethods) do
        if c_mt.impl[method] then
          i_mt[method] = c_mt.impl[method]
        end
      end

      --print("I:",class, instance, ">", arg)
      return instance
--]]      
    end,

    impl = impl,
    reflection = object_reflection(impl),
  }


  return proxy
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
  --print("C:",impl,inst,getmetatable(inst), parent)
  return inst
end


is_a = function(object, class)
  local o_p, o_i = object_manipulators(object, false)
  local c_p, c_i = object_manipulators(class, false)

  if not o_p or not o_i or not c_p or not c_i then -- it is not pobably loxy inst
    return false
  end

  return c_i == getmetatable(o_i).__index
end
