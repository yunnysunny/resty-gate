local lrucache = require "resty.lrucache"

local peerCounter, err = lrucache.new(1024);

local _M = {};

_M.incr = function(key)
    if err then
        return 0, err
    end
    local count = peerCounter:get(key)
    if not count then
        count = 1
    else
        count = count + 1
    end
    peerCounter:set(key, count, 180) -- cached for 180s
    return count, nil
end
return _M
