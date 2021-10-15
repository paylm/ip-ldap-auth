## 本插件用于kong 多级认证

### 作用
结合IP 黑白名单和 ldap模块组合认证
认证顺序 -> IP黑名单 -> 白名单 -> ldap 认证

### 插件项目参考官方插件模板

```azure
git clone https://github.com/Kong/kong-plugin.git
```
目录结构如下：
```azure
$ tree
.
├── LICENSE
├── README.md
├── kong
│   └── plugins
│       └── myplugin
│           ├── handler.lua
│           └── schema.lua
├── kong-plugin-myplugin-0.1.0-1.rockspec
└── spec
    └── myplugin
        └── 01-access_spec.lua
5 directories, 6 files
```

kong插件主要有三个文件：

handler.lua 是包含插件逻辑处理相关代码。 schema.lua 包含插件的配置文件。 rockspec 文件是通过luarock安装时用的配置文件。

逻辑处理的代码根据openresty的不同处理阶段分成了不同的函数，根据插件的功能只需要在不同的函数中添加自己的业务逻辑。

### 本插件关键信息

schema.lua  配置文件
handler.lua 业务功能认证入口文件
ip.lua      ip校验基础函数类
ldap.lua    ldap认证基础函数类
asn1.lua    ldap认证基础信息类模块
access.lua  访问控制实现类
```azure
function _M.execute(conf)
  if conf.anonymous and kong.client.get_credential() then
    -- we're already authenticated, and we're configured for using anonymous,
    -- hence we're in a logical OR between auth methods and we're already done.
    return
  end
  -- 添加ip 认证
  local ok ,err = do_ip_check(conf)
  if ok then
     return
  end

  -- 添加ldap 认证
  local ok, err = do_authentication(conf)
  if not ok then
    if conf.anonymous then
      -- get anonymous user
      local consumer_cache_key = kong.db.consumers:cache_key(conf.anonymous)
      local consumer, err      = singletons.cache:get(consumer_cache_key, nil,
                                                      kong.client.load_consumer,
                                                      conf.anonymous, true)
      if err then
        return error(err)
      end

      set_consumer(consumer)

    else
      return kong.response.error(err.status, err.message, err.headers)
    end
  end
end
```

### 安装调试
1. 修改kong.conf文件，添加或者修改下面的配置项。
```
# bundled 表示kong内置的所有插件
plugins = bundled,ip-ldap-auth
# 添加huidu插件目录绝对路径
lua_package_path = /vikadata/kong/kong-plugin-ip-ldap-auth/?.lua;./?.lua;./?/init.lua;;
```
注: 真实路径为 /vikadata/kong/kong-plugin-ip-ldap-auth/kong/plugins/ip-ldap-auth
2. 修改完成后，保存启动kong
```azure
#启动
kong start -c kong.conf --vv
#重启
kong reload -c /vikadata/kong/conf/kong.conf
```

3. 查看或配置插件
```azure
curl http://127.0.0.1:81/plugins/enabled
```
响应信息如下
```azure
{
    "enabled_plugins":[
        "acme",
        "grpc-web",
        "grpc-gateway",
        "ip-ldap-auth",
        "jwt",
        "acl",
        "correlation-id",
        "cors",
        "oauth2",
        "tcp-log",
        "udp-log",
        "file-log",
        "http-log",
        "key-auth",
        "hmac-auth",
        "basic-auth",
        "ip-restriction",
        "request-transformer",
        "response-transformer",
        "request-size-limiting",
        "rate-limiting",
        "response-ratelimiting",
        "syslog",
        "loggly",
        "datadog",
        "ldap-auth",
        "statsd",
        "bot-detection",
        "aws-lambda",
        "request-termination",
        "azure-functions",
        "zipkin",
        "pre-function",
        "post-function",
        "prometheus",
        "proxy-cache",
        "session"
    ]
}
```
或通过Konga 配置，如 plugins -> other 位置

### 正式环境打包部署

正式环境部署
正式环境通过 luarocks 来部署。

编辑kong-plugin-ip-ldap-auth-0.1.0-1.rockspec文件，修改下面几个配置
```azure
package = "kong-plugin-ip-ldap-auth”
source = {
url = "https://github.com/paylm/kong-plugin-ip-ldap-auth.git",
tag = "0.1.0"
}
```
下面是本地mac上安装的情况


```azure
$ luarocks make —-verbose
```
kong-plugin-ip-ldap-auth 0.1.0-1 is now installed in /usr/local/opt/kong (license: Apache 2.0)
mac 下安装完成后lua代码会安装到
```azure
/usr/local/opt/kong/share/lua/5.1/kong/plugins/ip-ldap-auth
```
linux会安装到这个目录下

```azure
/usr/local/share/lua/5.1/kong/plugins/ip-ldap-auth
```
这样就不需要在kong.conf中配置绝对路径了。

安装完成后需要运行kong restart命令才能生效。


