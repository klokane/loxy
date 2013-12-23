require 'busted'
require 'object'

describe("object special cases", function()
  it("handle false attribute", function()
    local c = object({
      yes = true,
      no = false,
    })()
    assert.is.equal(c.yes, true)
    assert.is.equal(c.no, false)
  end)
end)
