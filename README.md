 # LOXY

loxy is shortage from 'Lua Object proXY'

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

You can overwrite 'property' in constructor:

    circle = Circle{ radius = 10 }    
    area = circle:getArea() 
    assert(area == 10^2*PI)

## Setters/Getters - syntax sugar


loxy provide syntax sugar for objects

In example with Circle you can access `circle.radius` throught `circle:getRadius()` method or method `circle:getArea()` as property `cicrcle.area'

    circle = Circle{ radius = 10 }    
    assert( circle.area == 10 * PI)
    assert( circle:getRadius() == 10)

Same sugar is used for setters

We will extend our class Circle with setter:

    Circle = object({
      radius = 0,
      getArea = function(self)
        return self.radius^2 * PI
      end,
      setArea = function(self, area)
        self.radius = math.sqrt(area / PI)
      end,
    })

Now You use Circle in ollowing way:

    c = Circle({ area = 20^2*PI })
    assert(c.radius == 20)

There is (in current version) __limitation__ about getter/property: 

__You may not define property and getter for one attribute in same time__

Reason is following: while accessing property, getter has higgher priority than direct access to property. 
If you access propery in getter calling, loxy again invoke getter.

If you try to do it, you will receive 'error' while accessing attribute (or getter):

    C = object({attr = 0, getAttr = function(self) return self.attr end})
    c = C()
    print(c.attr)


    ./loxy/object.lua:142: undefined behavior, there are defined both property and getter for: attr
    stack traceback:
            [C]: in function 'error'
            ./loxy/object.lua:142: in function <./loxy/object.lua:115>
            ...
            stdin:1: in main chunk
            [C]: ?

You can avoid this limitation by using property with diferent name (e.g started by underscore) inside setter/getter

    C = object({
      _attr = 0,
      getAttr = function(self) return self._attr end,
      setAttr = function(self, attr) self._attr = attr end,
    })

    c = C{ attr = 5 }
    assert(c.attr == 5)

    c.attr = 6
    assert(c.attr == 6)



### Anonymous class


As side effect of calling object() you can directly invoke constructor. 
You will create, by this way, instance of 'anonymous class' (see pair of parenthesis at end of line - this will invoke constructor and  will return new instance) 

    c = object({a = 0})()



## Inheritance


Loxy implements simple inheritance mechanism throught call `object(<Parent>, <Class implemtation>)`

    Base = object({ 
      name = 'Base', 
      selfIntroduce = function(self) 
        return "Hello, my name is " .. self.name 
      end 
    })

    Class = object(Base,{ 
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

loxy define two kinds of constructor mechanism. 

### Implicit constructor

Will just copy received table to object. If there are setters for attribute, implicit constructor invoke them.
Setter invocation you can avoid this behavior if you send second parameter `false` to constructor

    C = object({ a = 0, setA = function(self, a) self.a = a + 1 end })

    local c1 = C()     -- empty constructor call
    assert(c1.a == 0)  -- if no constructor - it will inherit value from class C

    local c2 = C{ a = 3 }  -- implicit constructor invoked
    assert(c2.a == 4)      -- assignment in constructor invoke setter mechanism if setter exists - it is default behavior

    local c3 = C({ a = 3 }, false) -- avoid setters invocation while implicit c-tor
    assert(c3.a == 3)             

### Explicit c-tor

You can define your own constructor by `__init()` method. Then implicit constructor is not defined. Instead, all received params are sent to `__init()` method

    C = object({ 
      a = 0, 
      __init = function(self, a) -- explicit c-tor
        self.a = a + 2 
      end 
    })

    local c = C(2)  -- this will invoke your __init() method instead of implicit constructor

## Override metamethods

Loxy allows you override metamehods:
    C = object({
      name = 'class'
      __tostring = function(self)
        return "I'm: " .. self.name
      end
    })

    c = C{ name = 'instance of C'}
    print(c) -- will print: "I'm: instance of C"

Accepted overrided metamethods are:

  `__tostring`, `__concat`,
  `__add`, `__mul`, `__sub`, `__div`, `__unm`, `__pow`,
  `__eq`, `__lt`, `__le`,
}

## Runtime Type Indentification

Loxy provide `is_a()` function to RTI

    C = object({})

    c = C()

    assert(is_a(c,C) == true) -- invoke as function
    assert(c:is_a(C) == true) -- invoke as object method

`is_a()` function allows testing to any other type not just loxy class

    assert(c:is_a({}) == false)
    assert(is_a({},C) == false)



## Callback/signal mechanism

Part of loxy library is signal/callback handlers.
By this mechanism you can invoke callback in properly situation

    Class = object({
      attr = 0,
      onAttrChanged = signal(), -- define signal handle
      setAttr = function(self, attr)
        if attr ~= self.attr then
          self.onAttrChanged(attr)
          self.attr = attr
        end
      end,
    })

    counter = 0
    c = Class()

    c.onAttrChanged:connect(function() counter = counter + 1 end)

    c.attr = 1 -- now is setter invoked and will emit signal
    assert(counter == 1)

    c.attr = 1 -- invoke setter again, but signal is not emited due to condition 'attr ~= self.attr'
    assert(counter == 1)

    c.attr = 10 -- invoke setter again, it will emit signal
    assert(counter == 2)

__Signal__s can be used independently on object machanism

Mechanism is very simple, you will create instance of signal

    s = signal()

you will connect callback(s) to signal instace

    s:connect(function(arg) print(arg) end)
    s:connect(function(arg) print(arg + 1) end)

and now invocation of signal instance will emit all connected callbacks

    s(1)

will invoke connected callbacks

You can invoke signal too by explicit calling member function emit()

    s:emit(<param>)

Both signal emits are equal. 
All params sent to signal will receive function connected to signal

    > s = signal()
    > s:connect(function(...) print(...) end)
    > s(1,3,4,8,{},6)
    1       3       4       8       table: 0x9d281a8        6
    > 

### Callbacks 


Calbacks are not limited to closures you can connect many diferent types of callbacks

    s = signal()

    s:connect(function() print('closure') end) 

    f = function() print('function') end
    s:connect(f) 

    t = { m = function(self) print('table method') end}
    s:connect(t.m) 

    ti = { m = function(self) print('table method - by instance') end}
    s:connect(ti,ti.m) 

    ts = { m = function(self) print('table method - by name') end}
    s:connect(ts,'m') 

    tc = setmetatable({},{__call = function() print('metamethod') end})
    s:connect(tc)

    o = object({ m = function() print('loxy object method') end})()
    s:connect(o,o.m)

    o = object({ m = function() print('loxy object method - by name') end})()
    s:connect(o,'m')

output from emiting  s() will be:

    closure
    function
    table method
    table method - by instance
    table method - by name
    metamethod
    loxy object method
    loxy object method - by name

## Signal marshalling

By marshalling mechanism you can receive returned value from callbacks

    s = signal()
    s:connect(function() return 1 end)
    r = s()
    assert(r == 1)

Marshalling mechanism You will inject by parameter to `signal()`

If `signal()` has no param then preddefined marshaller.last is used

There are twe preddefined marshalers
  * __marshaller.last__ - signal emit will return result of last callback
  * __marshaller.table__ - signal emit will return table with result of every one registered callback

As default marshaller is used __marshaller.last__

    sl = signal(marshaller.last)
    sl:connect(function() return 1 end)
    sl:connect(function() return 2 end)
    sl:connect(function() return 3 end)
    r = sl() -- r has value 3 - result of last registered callback

A table marshaller is similar

    st = signal(marshaller.table)
    st:connect(function() return 1 end)
    st:connect(function() return 2 end)
    st:connect(function() return 3 end)
    r = st() -- r is now table {1,2,3} - collected result of all callback

Both preddefined marshallers will store just _first_ retuned value of calback
eg. for function() return 9,7,5,3,1 end will be marshaled just value 9

### Own marshallers

You can define your own marshallers (for example return sum of callbacks)

API for marshaller is very simple

    m = marshaller() -- must be callable - it will create instance
    m:add(self,val)  -- add next result of callback
    m:res(self)      -- return result of callback

For example there id marshhaler which will return sum of returned values

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

## TODOs

 * access parent methods via 'super'
 * add extension method
 * allow memoize getters
 * ??? allow "protected" attrs via "_" prefix 
 * add extension methods
