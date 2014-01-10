# LOXY

__Loxy__ is short from 'Lua Object proXY'

Usage:

## Define 'class'

    require 'loxy'

    local PI = 3.14
    Circle = object({
      radius = 0,
      getArea = function(self)
        return self.radius^2 * PI
      end,
    })

## Create instance of class

    circle = Circle()
    circle.radius = 10

    area = circle:getArea() 
    assert(area == 10^2*PI)

You can overwrite property `a` for instance in constructor:

    circle = Circle{ radius = 10 }    
    area = circle:getArea() 
    assert(area == 10^2*PI)

More about constructor see later in section __Constructor__

## Error on unknown attribute/method

__Loxy__ will throw error if you try access undefined attribute or method (there is exception for setters/getters - see next section)
There is little difference between Loxy and traditional Lua access for attribute

    t = {}
    print(t.a)     -- it will be OK due to Lua returns nil for nonexisting attr

but with __loxy__ you will get `error`.

    o = ({})()     -- create instance of anonymous class - see section "Anonymous class"
    print(o.a)     -- but this throw error "read unknown attribute: d"

## Setters/Getters - syntax sugar

In example with `Circle` you can access:
  - property `circle.radius` throught `circle:getRadius()` method. 
  - method `circle:getArea()` by property `cicrcle.area`

This is __Loxy__ syntax sugar provided for objects.

    circle = Circle{ radius = 10 }    
    assert( circle.area == 10 * PI)
    assert( circle:getRadius() == 10)

Same syntax sugar is used for setters

We will extend our class `Circle` with setter:

    Circle = object({
      radius = 0,
      getArea = function(self)
        return self.radius^2 * PI
      end,
      setArea = function(self, area)
        self.radius = math.sqrt(area / PI)
      end,
    })

Now You can use `Circle` in following way:

    c = Circle({ area = 20^2*PI })
    assert(c.radius == 20)

There is (in current version) __limitation__ around getter/property: 

__You may not define property and getter for one attribute in same time__

Reason is following: while accessing property, getter has higgher priority than direct access to property. 
Then if you accessing property inside getter calling, __loxy__ invoke getter repeatly.

    C = object({                
      attr = 0,                 -- attr
      getAttr = function(self)  -- attr getter
        return self.attr 
      end
    }) -- This is invalid: both property and getter are defined
    c = C()
    print(c.attr)

If you try to do it, you will get `error` while accessing property or getter:

    ./loxy/object.lua:142: undefined behavior, there are defined both property and getter for: attr
    stack traceback:
            [C]: in function 'error'
            ./loxy/object.lua:142: in function <./loxy/object.lua:115>
            ...
            stdin:1: in main chunk
            [C]: ?

You can avoid this limitation by using _property with diferent name_ (e.g started by underscore) for use inside __setter/getter__

    C = object({
      _attr = 0,
      getAttr = function(self) return self._attr end,
      setAttr = function(self, attr) self._attr = attr end,
    })

    c = C{ attr = 5 }
    assert(c.attr == 5)

    c.attr = 6
    assert(c.attr == 6)


## Inheritance

__Loxy__ implements simple inheritance mechanism throught call `object(<Parent>, <Class implementation>)`

    Base = object({ 
      name = 'Base', 
      selfIntroduce = function(self) 
        return "Hello, my name is " .. self.name 
      end 
    })

    Class = object(Base,{  -- there is 'Base' used as parent of 'Class'
      name = 'Class' 
    }) 

    b,c = Base(),Class()
    assert(b:selfIntroduce() == 'Hello, my name is Base')
    assert(c:selfIntroduce() == 'Hello, my name is Class')

More complex example you can see in file `spec/inheritance_spec.lua`:

    local shape = object({ -- create base object
      name = 'shape',
      draw = function(self) return 'draw '..self.name end
    })

    local s = shape() -- create shape instance
    assert.is.equal(shape:draw(), 'draw shape')
    s.name = 'shape instance' -- overwrite name in instance
    assert.is.equal(s:draw(), 'draw shape instance')

    local circle = object(shape,{ -- inherit from shape
      name = 'circle',
      radius = 0,
      getArea = function(self)
        return self.radius^2 * 3.14
      end
    })

    local c = circle() -- create instance
    c.radius = 10      -- set instance
    assert.is.equal(c:draw(), 'draw circle') -- try to invoke parent class

    local filledCircle = object(circle,{ -- inherit from cicrle, but override draw
      fill = 'none',
      draw = function(self) return string.format("draw %s %s", self.fill, self.name) end,
    })
    local fc = filledCircle({ fill = 'red' })
    assert.is.equal(fc:draw(), 'draw red circle') -- invoke overrided draw()

## Constructor

__Loxy__ provide two kinds of constructor mechanism. 

### Implicit constructor

Will just copy received table to object. If there are setters for attribute, implicit constructor invoke them.
You can avoid __setter invocation in constructor call__ by second parameter `false` to constructor

    C = object({ 
      a = 0, 
      setA = function(self, a) 
        self.a = a + 1 
      end 
    })

    local c1 = C()     -- empty constructor call
    assert(c1.a == 0)  -- no parmeters to constructor - it will inherit value from class C

    local c2 = C{ a = 3 }  -- implicit constructor invoked
    assert(c2.a == 4)      -- assignment in constructor invoke setter mechanism if setter exists - it is default behavior

    local c3 = C({ a = 3 }, false) -- avoid setters invocation while implicit c-tor
    assert(c3.a == 3)             

### Explicit c-tor

You can define your own constructor by `__init()` method. In this case implicit constructor will not be used. Instead, all received params are sent to `__init()` method

    C = object({ 
      a = 0, 
      __init = function(self, a) -- explicit c-tor
        self.a = a + 2 
      end 
    })

    local c = C(2)  -- this will invoke your __init() method instead of implicit constructor
    assert(c.a == 4)

See, `__init()` will receive as first param `self`

## Override metamethods

__Loxy__ allows override metamethods:

    C = object({
      name = 'class',
      __tostring = function(self)
        return "I'm: " .. self.name
      end,
    })

    c = C{ name = 'instance of C' }
    print(c) -- will print: "I'm: instance of C"

Accepted overrided metamethods are:

  * strings:  `__tostring`, `__concat`,
  * arithmetic: `__add`, `__mul`, `__sub`, `__div`, `__unm`, `__pow`,
  * comparable: `__eq`, `__lt`, `__le`,
}

## Runtime Type Indentification

__Loxy__ provide `is_a()` function to RTI

    C = object({})

    c = C()

    assert(is_a(c,C) == true) -- use as function
    assert(c:is_a(C) == true) -- use as object method

`is_a()` function allows testing is not limited to __loxy__ classes. You can compare to any other Lua type

    assert(c:is_a({}) == false)
    assert(is_a({},C) == false)
    assert(is_a(c,1)  == false)

## Callback/signal mechanism

Part of __loxy__ library is `signal/callback` mechanism.
This mechanism allows invoke callback in properly situation

    Class = object({
      attr = 0,
      onAttrChanged = signal(),     -- define signal handler
      setAttr = function(self, attr)
        if attr ~= self.attr then   -- emit signal only if value really changes
          self.onAttrChanged(attr)
          self.attr = attr
        end
      end,
    })

    counter = 0 
    c = Class()

    c.onAttrChanged:connect(function() counter = counter + 1 end)

    c.attr = 1                      -- now is setter invoked and will emit signal
    assert(counter == 1)

    c.attr = 1                      -- invoke setter again, 
    assert(counter == 1)            -- but signal was not emited due to condition 'attr ~= self.attr'

    c.attr = 10                     -- invoke setter again, it will emit signal
    assert(counter == 2)

__Signal__s can be used independently on __loxy__ objects

Mechanism is very simple, you will create instance of signal

    s = signal()

you will connect some callback(s) to signal 

    s:connect(function(arg) print(arg) end)
    s:connect(function(arg) print(arg + 1) end)

and now by calling `signal:emit()` you will invoke all connected callbacks and send param `1` to them

    s:emit(1)

There is additionaly syntax sugar for emitting via Lua `__call` metamethod

    s(1) -- it is equal to call s:emit(1)

### Signal params

All parameters sent to signal will receive function connected to signal

    > s = signal()
    > s:connect(function(...) print(...) end)
    > s(1,3,4,8,{},6)
    1       3       4       8       table: 0x9d281a8        6
    > 

### Callbacks 

Calbacks are not limited to closures. You can connect to signal many diferent types.

    s = signal()

    s:connect(function() print('closure') end) 

    f = function() print('function') end
    s:connect(f) 

    t = { m = function(self) print('table method') end}
    s:connect(t.m) 

    ti = { m = function(self) print('table method - with instance') end}
    s:connect(ti,ti.m)

    ts = { m = function(self) print('table method - by function name') end}
    s:connect(ts,'m') 

    tc = setmetatable({},{__call = function() print('metamethod') end})
    s:connect(tc)

    o = object({ m = function() print('loxy object method') end})()
    s:connect(o,o.m)

    os = object({ m = function() print('loxy object method - by name') end})()
    s:connect(os,'m')

output from emiting `s()` will be:

    closure
    function
    table method
    table method - with instance
    table method - by function name
    metamethod
    loxy object method
    loxy object method - by name

Params sent to `:connect()` are internally packed by `callback()` and later invoked by `callback:invoke()`

You can see, in `ti`, `ts` `o` and `os` usage of instance callback. 
In this case, there is additionaly sent `self` as fisrt param.
It use Lua syntax sugar. `t:m()` is same as `t.m(t)`. Same logic is used in callback.

## Signal returned values - marshalling

By marshalling mechanism you can receive returned value(s) from callback(s)

    s = signal()
    s:connect(function() return 1 end)
    r = s()
    assert(r == 1)

Marshalling mechanism You will inject via parameter to `signal()`

If you don't provide marshaller to `signal()`, then preddefined `marshaller.last` is used

There are two preddefined marshalers:

  * __marshaller.last__ - signal emit will return result of last callback
  * __marshaller.table__ - signal emit will return table with result of every one registered callback


Last value marshaller usage:

    sl = signal(marshaller.last)        -- it is equal to call signal() w/o parameter
    sl:connect(function() return 1 end)
    sl:connect(function() return 2 end)
    sl:connect(function() return 3 end)
    r = sl() -- r has value 3 - result of last registered callback

A table marshaller usage is similar

    st = signal(marshaller.table)
    st:connect(function() return 1 end)
    st:connect(function() return 2 end)
    st:connect(function() return 3 end)
    r = st() -- r is now table {1,2,3} - collected result of all callback

Both preddefined marshallers will store just _first_ retuned value of callback
eg. for `function() return 9,7,5,3,1 end` will be stored just _first_ value `9`

### Own marshallers

You can create your own marshallers (for example return sum of callbacks)

API for marshaller is very simple

    m = marshaller() -- must be callable - it will create marshaller instance
    m:add(self,val)  -- called on every callback invocation
    m:res(self)      -- return result collected by add()

For example there is marshaller which will return sum of returned values

    SumMarshaller = function()
      return {
        val = 0,
        add = function(self,val)
          self.val = self.val + val
        end,
        res = function(self)
          return self.val
        end,
      }
    end

And how to use it

    s = signal(SumMarshaller)

    s:connect(function() return 5 end)
    s:connect(function() return 6 end)
    s:connect(function() return 7 end)

    assert(s() == 18)

## Anonymous class

As side effect of calling `object()`` you can directly invoke constructor. 
You will create, by this way, instance of 'anonymous class' 

See pair of parenthesis at end of line - this will invoke constructor and  will return new instance

    c = object({a = 0})()


## TODOs

 * access parent methods via 'super'
 * add extension method
 * allow memoize getters
 * ??? allow "protected" attrs via "_" prefix 
 * add extension methods
