local ngx_print = ngx.print
local ngx_log = ngx.log
local ngx_DEBUG = ngx.DEBUG
local ngx_ERR = ngx.ERR
local ngx_var = ngx.var
local ngx_ctx = ngx.ctx
local ngx_header = ngx.header
local ngx_req = ngx.req
local ngx_sub = ngx.re.sub
local ngx_say = ngx.say
local HTTP_INTERNAL_SERVER_ERROR = ngx.HTTP_INTERNAL_SERVER_ERROR
local HTTP_BAD_GATEWAY = ngx.HTTP_BAD_GATEWAY

local ngx_req_get_method = ngx_req.get_method
local ngx_req_get_headers = ngx_req.get_headers
local str_lower = string.lower
local ngx_exit = ngx.exit
local sharedServices = ngx.shared.services
local cache = require "cache"
local util = require("util")

local function getPeer()
    
    local clusterId = ngx_ctx.clusterId
    local serviceName = ngx_ctx.serviceName
    -- ngx_log(ngx_DEBUG, "get peer from " .. serviceName .. " of " .. clusterId)
    local keyShared = clusterId .. ":" .. serviceName
    local peersString = sharedServices:get(keyShared)
    if not peersString then
        ngx_print("service " .. serviceName .. " in " .. clusterId .. " not found")
        ngx_exit(404)
        return
    end

    local peers = util.str_split(peersString, ",")
    if (not peers) or (#peers == 0) then
        ngx_print("service " .. serviceName .. " in " .. clusterId .. " not found")
        ngx_exit(404)
        return
    end
    if #peers == 1 then
        return peers[1]
    end
    if ngx_ctx.balancer_mod == 'random' then
        return peers[math.random(#peers)]
    end
    local value, err = cache.incr(keyShared)
    if err then
        ngx_log(ngx_ERR, "counter increase error: ", err)
        ngx_exit(HTTP_INTERNAL_SERVER_ERROR)
        return
    end
    value = (value % #peers) + 1
    return peers[value]
end

local httpc = require("resty.http").new()
-- http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.5.1
local HOP_BY_HOP_HEADERS = {
    ["connection"]          = true,
    ["keep-alive"]          = true,
    ["proxy-authenticate"]  = true,
    ["proxy-authorization"] = true,
    ["te"]                  = true,
    ["trailers"]            = true,
    ["transfer-encoding"]   = true,
    ["upgrade"]             = true,
    ["content-length"]      = true, -- Not strictly hop-by-hop, but Nginx will deal
                                    -- with this (may send chunked for example).
}

-- First establish a connection
local peerString = getPeer()
local peerData = util.str_split(peerString, ":")
local ok, err = httpc:connect({
    scheme = "http",
    host = peerData[1],
    port = peerData[2],
    pool_size = ngx_ctx.http_client_pool_size or 32,
    backlog = ngx_ctx.http_client_backlog or 32
})
if not ok then
    ngx_log(ngx_ERR, "connection failed: ", err)
    ngx_say("connect to upstream " .. peerString .." failed")
    ngx_exit(HTTP_BAD_GATEWAY)
    return
end
local headeres = ngx_req_get_headers()
headeres["Connection"] =  "Keep-Alive"
-- Then send using `request`, supplying a path and `Host` header instead of a
-- full URI.

local path = ngx_ctx.path
-- if path == nil then
--     path = ngx_sub(ngx_var.request_uri, ngx_var.location, "/")
-- end
local res, err = httpc:request({
    method = ngx_req_get_method(),
    path = path,
    body = httpc:get_client_body_reader(),
    headers = headeres,
})
if not res then
    ngx_log(ngx_ERR, "request failed: ", err)
    ngx_say("request upstream " .. peerString .. " failed")
    ngx_exit(HTTP_BAD_GATEWAY)
    return
end
if res.status >= 400 then
    ngx_say("request upstream " .. peerString .. " with status " .. res.status)
    ngx_exit(res.status)
    return
end
-- Filter out hop-by-hop headeres
for k, v in pairs(res.headers) do
    if not HOP_BY_HOP_HEADERS[str_lower(k)] then
        ngx_header[k] = v
    end
end
-- At this point, the status and headers will be available to use in the `res`
-- table, but the body and any trailers will still be on the wire.

-- We can use the `body_reader` iterator, to stream the body according to our
-- desired buffer size.
local reader = res.body_reader
local buffer_size = 8192
repeat
    local buffer, err = reader(buffer_size)
    if err then
        ngx_log(ngx_ERR, "read upstream response " .. peerString .. " failed ", err)
        ngx_say("read upstream response " .. peerString .. " failed")
        ngx_exit(HTTP_BAD_GATEWAY)
        break
    end

    if buffer then
        local ok, print_err = ngx_print(buffer)
        if not ok then
            ngx_log(ngx_ERR, print_err)
            break
        end
    end
until not buffer

local ok, err = httpc:set_keepalive(ngx_ctx.http_client_keepalive_ms or 1800000)
if not ok then
    ngx_log(ngx_ERR,"failed to set keepalive: ", err)
    -- return
end
