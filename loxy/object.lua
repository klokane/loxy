require 'loxy.signal'

local constructor_name = '__init'
local overridable_metamethods = { 
  '__tostring', '__concat',
  '__add', '__mul', '__sub', '__div', '__unm', '__pow',
  '__eq', '__lt', '__le',
}

local print_ = print
local print = function() end

local s_upper = string.upper
local s_lower = string.lower
local s_gsub  = string.gsub
local s_match = string.match

local pairs = pairs
local setmetatable = setmetatable
local getmetatable = getmetatable

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

--[[
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
      return rawget(self.obj,constructor_name) ~= nil
      --return self:hasMethod(constructor_name)
    end,
  }
end
--]]

local object_manipulators = function(instance)
  local proxy = getmetatable(instance)
  local impl = proxy and proxy.impl or nil

  return proxy, impl
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

      local index = impl[attr]

      --print("R:", instance, impl, attr, type(index))

      if type(index) == 'function' then -- it is direct method call (setter include)
        --print("DF") 
        if s_match(attr,"^get%u") then -- ask for getter check duplicit property
          local prop_name = util.toProperty(attr)
          if impl[prop_name] ~= nil then
            error('undefined behavior, there are defined both property and getter for: '.. attr)
          end
        end
        return function(self, ...)
          if self == instance then 
            return index(impl, ...)
          end
          return index(self,...)  
        end
      elseif attr == 'is_a' then
        return function(instance,class) return is_a(instance, class) end
      elseif index ~= nil then -- it is property
        local getter_name = util.toGetter(attr)
        if impl[getter_name] ~= nil then
          error('undefined behavior, there is defined both property and getter for: '.. attr)
        end
        --print("DP")
        return index
      else -- no method, no property look for other solution
        if s_match(attr,"^get%u") then -- ask for getter -> look for propery
          local prop_name = util.toProperty(attr)
          local prop = impl[prop_name]
          --print("G->P:",attr,prop_name)
          if prop ~= nil then
            return function() return prop end
          end
        elseif s_match(attr,"^set%u") then -- ask for setter -> look for propery
          local prop_name = util.toProperty(attr)
          --print("S->P:",attr,prop_name)
          if impl[prop_name] ~= nil then
            return function(_,val) impl[prop_name] = val  end
          end
        else -- asking for property -> look for getter
          local getter_name = util.toGetter(attr)
          --print("P->G",attr,getter_name)
          local getter = impl[getter_name]
          if getter ~= nil then
            return getter(impl)
          end
        end
        --print('N/A')
      end
      error("read unknown attribute: "..attr)
    end,

    __newindex = function(instance, attr, value) 
      local proxy = getmetatable(instance)
      local impl = proxy.impl

      --print("W:", instance, impl, attr, type(index), value)
      local setter_name = util.toSetter(attr)
      local setter = impl[setter_name]

      if setter ~= nil then
        setter(impl,value)
        return
      elseif impl[attr] ~= nil then
        impl[attr] = value
        return
      end

      error("write unknown attribute: "..attr)
    end,

    __call = function(class, ...)
      local impl = {}
      local cimpl = getmetatable(class)['impl']
      local init = cimpl[constructor_name]

      if not init and #arg == 2 and type(arg[1]) == 'table' and arg[2] == false then
        impl = arg[1]
      end

      local instance = object(class, impl)

      if not init and #arg == 1 and type(arg[1]) == 'table' then
        local c = arg[1]
        for k,v in pairs(c) do
          instance[k] = v
        end
      end


      if init then -- explicit c-tor
        init(instance, unpack(arg))
      end

      -- disable c-tor for instance
      getmetatable(instance).__call = nil

      -- connect overridable metamethods to proxy
      local proxy = getmetatable(instance)
      for _,method in pairs(overridable_metamethods) do
        local mm = cimpl[method]
        if mm ~= nil then
          proxy[method] = mm
        end
      end
      
      --print("I:",class, "=>", instance)
      return instance

    end,

    impl = impl,
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
  local o_p, o_i = object_manipulators(object)
  local c_p, c_i = object_manipulators(class)

  if not o_p or not o_i or not c_p or not c_i then -- it is not pobably loxy inst
    return false
  end

  return c_i == getmetatable(o_i).__index
end
