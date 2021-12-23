local resty_consul = require('resty.consul')
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
local sharedServices = ngx.shared.services
local ngx_log = ngx.log
local ngx_DEBUG = ngx.DEBUG
local ngx_ERROR = ngx.ERR
local new_timer = ngx.timer.at
local filter = os.getenv("CONSUL_SERVICE_FILTER") or ''
local consulAddr = os.getenv("CONSUL_ADDR")
local host = "127.0.0.1"
local port = 8500
local util = require("util")
if consulAddr then
    local consulEndpoint = util.str_split(consulAddr, ":")
    if #consulEndpoint == 2 then
        host = consulEndpoint[1]
        port = tonumber(consulEndpoint[2])
    end
end

ngx_log(ngx_DEBUG, "init consul with host " .. host .. " port " .. port, consulAddr)
local consul = resty_consul:new({
    host            = host,
    port            = port,
    connect_timeout = (60*1000), -- 60s
    read_timeout    = (60*1000), -- 60s
})

local function getDcs()
    local res, err = consul:get("/catalog/datacenters")
    if not res then
        ngx_log(ngx_ERROR, err)
        return nil
    end
    -- ngx_log(ngx_DEBUG, #res.body)
    return res.body
end

local function getServices(dc)
    -- ngx_log(ngx_DEBUG, "begin get services from " .. dc )
    local res, err = consul:get("/catalog/services",{
        dc = dc,
        filter = filter
    })
    if not res then
        ngx_log(ngx_ERROR, err)
        return nil
    end
    local services = {}
    for service, _ in pairs(res.body) do
        table.insert(services, service)
    end
    ngx_log(ngx_DEBUG, "get " .. #services .. " services from " .. dc)
    return services
end

local function getServicePeers(dc, name)
    -- ngx_log(ngx_DEBUG, "get peers from " .. name .. " of " .. dc)
    local res, err = consul:get("/health/service/" .. name, {
        dc = dc,
    })
    if not res then
        ngx_log(ngx_ERROR, err)
        return nil
    end
    local result = res.body
    local peers = {}
    for i=1, #result do
        local health = result[i]
        if not (health.Service and health.Checks) then
            ngx_log(ngx_ERROR, "invalid health data, the Service or Checks is none " .. name .. " from " .. dc)
            goto continue
        else
            local ip = health.Service.Address
            local port = health.Service.Port
            local checks = health.Checks
            if (not checks) or (#checks == 0) then
                ngx_log(ngx_ERROR, "Checks is empty " .. name .. " from " .. dc)
                goto continue
            end
            for j=1, #checks do
                if checks[j].Status ~= "passing" then
                    ngx_log(ngx_ERROR,  name .."'s checks is " .. checks[j].Status .. " from " .. dc)
                    goto continue
                end
            end
            -- ngx_log(ngx_DEBUG, "get peer of service " .. name .. " in " .. dc)
            table.insert(peers, ip .. ":" .. port)
        end
        
        ::continue::
    end
    return table.concat(peers, ",")
end

local function getServiceList()
    local dcs = getDcs()
    if dcs == nil then
        return
    end
    if #dcs == 0 then
        ngx_log(ngx_ERROR, "dc is empty")
        return
    end
    for i = 1, #dcs do
        local dc = dcs[i]
        local ok, services = wait(spawn(getServices, dc))
        if not ok then
            ngx_log(ngx_ERROR, "get service form " .. dc .. " error")
            return
        end
        if #services == 0 then
            ngx_log(ngx_DEBUG, "get none service")
            goto continue
        end
        for j=1, #services do
            local service = services[j]
            local ok, peers = wait(spawn(getServicePeers, dc, service))
            if not ok then
                ngx_log(ngx_ERROR, "get ip from " .. dc .. " of " .. service .. " failed")
                goto continue
            end
            local keyShard = dc .. ":" .. service
            -- ngx_log(ngx_DEBUG, "get peer of service " .. service .. " in " .. dc .. " ", #peers)
            local success, err, forcible = sharedServices:set(keyShard, peers)
            if not success then
                ngx_log(ngx_ERROR, "save shared failed", err)
                goto continue
            end
            if forcible then
                ngx_log(ngx_ERROR, "the service shared memory is not enough")
            end
            -- ngx_log(ngx_DEBUG, "saved service string " .. sharedServices:get(keyShard))
        end
        
        ::continue::
    end
end


local delay = 5
local check

check = function(premature)
    getServiceList()
    if not premature then
        local ok, err = new_timer(delay, check)
        if not ok then
        ngx_log(ngx_ERROR, "failed to create timer: ", err)
            return
        end
    end
end

if 0 == ngx.worker.id() then
    local ok, err = new_timer(0, check)
    if not ok then
        ngx_log(ngx_ERROR, "failed to create timer: ", err)
        return
    end
end


