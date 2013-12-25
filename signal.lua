require 'callback'

signal = {
  new = function()
    return setmetatable({
      cb_ = {},
      
      connect = function(self, ...)
        table.insert(self.cb_, callback(...))
      end,

      emit = function(self, ...)
        for i = 1,#self.cb_ do
          self.cb_[i]:invoke(...)
        end
      end,

      },{
      __call = function(t, ...)
        return t:emit(...)
      end,

      __concat = function(t, f)
        t:connect(f)
      end
      }
    )
  end
}
