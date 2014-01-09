
function callback(...)
  return setmetatable({
    cb = {...},
    invoke = function(self, ...)
      local v1, t1 = self.cb[1], type(self.cb[1])
      if #self.cb == 1 then
        if t1 == 'function' or t1 == 'table' then
          return v1(...)
        end
      elseif #self.cb == 2 then
        local v2, t2 = self.cb[2], type(self.cb[2])
        if t1 == 'table' and t2 == 'function' then
          return v2(v1, ...)
        elseif t1 == 'function' and  t2 == 'table' then
          return v1(v2, ...)
        elseif t1 == 'table' and  t2 == 'string' then
          return v1[v2](v1, ...)
        elseif t1 == 'string' and  t2 == 'table' then
          return v2[v1](v2, ...)
        end
        
      end
      error('unsupported callback type')
    end,
    },{
      __call = function(t, ...)
        return t:invoke(...)
      end,
    }
  )
end
