local ipmatcher = require "resty.ipmatcher"

local _M = {}

local ngx = ngx
local kong = kong
local error = error

function _M.match_bin(list, binary_remote_addr)
  local ip, err = ipmatcher.new(list)
  if err then
    return error("failed to create a new ipmatcher instance: " .. err)
  end

  local is_match
  is_match, err = ip:match_bin(binary_remote_addr)
  if err then
    return error("invalid binary ip address: " .. err)
  end

  return is_match
end

return _M;
