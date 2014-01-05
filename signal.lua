require 'callback'

--[[
-- Marshaller has defined interface (contract)
--   m = marshaller() -> create marshaller instance
--   - m:add() - collect result if invocation
--   - m:res() - return marshallerd value(s)
--
--   preddefind two marshallers:
--   last - return last value
--   table - return all values collected in table
--
--   signal receive as param type of marshaller,
--   if send - it will use marshaller.last
--]]

local t_insert = table.insert

marshaller = {
  last = function()
    return {
      val = nil,
      add = function(self,val)
        self.val = val
      end,
      res = function(self)
        return self.val
      end,
    }
  end,

  table = function()
    return {
      val = {},
      add = function(self,val)
        t_insert(self.val,val)
      end,
      res = function(self)
        return self.val
      end,
    }
  end,
}

function signal(m)
  m = m or marshaller.last
  return setmetatable({
    cb_ = {},
    marshaller = m,
    
    connect = function(self, ...)
      table.insert(self.cb_, callback(...))
    end,

    emit = function(self, ...)
      local m = self.marshaller()
      for i = 1,#self.cb_ do
        m:add(self.cb_[i]:invoke(...))
      end
      return m:res()
    end,

    },{
    __call = function(t, ...)
      return t:emit(...)
    end,
    }
  )
end
