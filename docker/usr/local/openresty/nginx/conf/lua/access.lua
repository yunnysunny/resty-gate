local util = require "util"
local ngx_ctx = ngx.ctx
local ngx_var = ngx.var
local array = util.str_split(ngx_var.uri,'/')
-- for i=1,#array do
--   ngx.log(ngx.DEBUG, array[i])
-- end 
local clusterId = array[2]
local serviceName = array[3]

ngx_ctx.path = "/" .. table.concat(array, '/', 4)
ngx_ctx.clusterId = clusterId
ngx_ctx.serviceName = serviceName

-- domain = serviceName .. '.service.' .. clusterId .. '.consul'
-- ngx_ctx.domain = domain