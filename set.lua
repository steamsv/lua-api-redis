local function close_redis(red)  
    if not red then  
        return  
    end  
    --释放连接(连接池实现)  
    local pool_max_idle_time = 10000 --毫秒  
    local pool_size = 100 --连接池大小  
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)  
    if not ok then  
        ngx.say("set keepalive error : ", err)  
    end  
end 

local redis = require("resty.redis")  

--创建实例  
local red = redis:new()  
--设置超时（毫秒）  
red:set_timeout(1000)  
--建立连接  
local ip = "127.0.0.1"  
local port = 6379
local redis_auth = "";
local ok, err = red:connect(ip, port)  
if not ok then  
    ngx.say("connect to redis error : ", err)  
    return close_redis(red)  
end
client:set_timeout(redis_connection_timeout)

-- 优化验证密码操作 代表连接在连接池使用的次数，如果为0代表未使用，不为0代表复用 在只有为0时才进行密码校验
local connCount, err = client:get_reused_times()
-- 新建连接，需要认证密码
if  0 == connCount then
    local ok, err = client:auth(redis_auth)
    if not ok then
        errlog("failed to auth: ", err)
        return
    end
    --从连接池中获取连接，无需再次认证密码
elseif err then
    errlog("failed to get reused times: ", err)
    return
end
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local key = args["key"]
local value = args["value"]
local ttl = args["ttl"]
ok, err = red:set(key, value)  
red:expire(key, ttl)  
if not ok then  
    ngx.say("set key error : ", err)  
    return close_redis(red)  
end  

close_redis(red)
