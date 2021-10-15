local access = require "kong.plugins.ip-ldap-auth.access"


local IPLdapAuthHandler = {
  PRIORITY = 1003,
  VERSION = "2.2.0",
}


function IPLdapAuthHandler:access(conf)
  access.execute(conf)
end


return IPLdapAuthHandler
