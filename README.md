### 项目计划 - 自定义代理服务器

#### 1. 总体目标

本项目的目标是开发一个多功能的代理服务器，能够在单一端口上处理HTTP(S)和SOCKS4(A)/SOCKS5的流量，同时支持动态更新代理规则，并使用自签名的CA证书进行HTTPS流量解密和重签名。服务器将具备以下功能：

1. **混合端口支持**：通过一个端口同时处理HTTP(S)和SOCKS流量，默认监听端口为`7769`，用户可通过配置文件或启动参数更改此端口。
2. **动态代理规则**：允许通过API动态更新代理规则，包括将请求的目标主机和端口重定向到新的目标主机和端口。
3. **HTTPS流量解密与重签名**：使用自签名CA证书解密HTTPS流量，并在转发时重签名请求。
4. **本地IP地址处理**：检测本地IP地址的请求并直接处理，而不通过代理转发。
5. **简单的Web管理界面**：通过HTTP接口管理代理规则，查看当前代理规则列表。
6. **日志管理**：基于不同的日志级别详细记录系统运行状态。

#### 2. 目录结构

为了简化代码维护和增强模块化，项目的目录结构进行了规划。目录结构如下：

```
ModifyHostProxyServer/
├── cmd/                     # 主应用入口
│   └── main.go              # 主程序文件
├── pkg/                     # 主要功能模块
│   ├── proxy/               # 代理功能模块
│   │   ├── http/            # HTTP(S)代理处理
│   │   │   ├── server.go    # HTTP服务器逻辑
│   │   │   ├── https.go     # HTTPS流量处理
│   │   │   └── handler.go   # HTTP请求处理逻辑
│   │   ├── socks/           # SOCKS代理处理
│   │   │   ├── socks4.go    # SOCKS4协议处理
│   │   │   ├── socks5.go    # SOCKS5协议处理
│   │   │   └── server.go    # SOCKS服务器逻辑
│   │   └── config/          # 配置模块
│   │       ├── cache.go     # 缓存配置管理
│   │       ├── config.go    # 配置加载和管理
│   │       ├── dns.go       # DNS配置管理
│   │       ├── proxy.go     # 代理服务器配置管理
│   │       ├── rules.go     # 代理规则管理
│   │       └── ssl.go       # SSL/TLS配置管理
│   ├── ca/                  # CA证书管理
│   │   ├── ca.go            # CA证书和密钥管理
│   │   └── cert.go          # 证书生成
│   └── logger/              # 日志管理
│       └── logger.go        # 日志记录实现
├── static/                  # 静态文件目录
│   └── ...                  # 网页资源等静态文件
├── config.yaml              # 默认代理规则配置文件
├── rootCA.pem               # 自签名CA证书
├── rootCA.key               # 自签名CA私钥
└── README.md                # 项目说明文件
```

#### 3. 具体分层实现逻辑

##### 3.1. 代理功能（pkg/proxy）

为了增强代码的可维护性，将代理功能进一步拆分为HTTP和SOCKS两个子模块，并为配置和代理规则管理创建独立模块。

- **HTTP模块（pkg/proxy/http/）**：
  - **Server.go**：  
    - 负责启动HTTP服务器并监听请求。
  - **HTTPS.go**：  
    - 处理HTTPS连接的解密、重签名和转发。
  - **Handler.go**：  
    - 处理HTTP请求的解析和代理转发，包括根据代理规则重定向请求。

- **SOCKS模块（pkg/proxy/socks/）**：
  - **Socks4.go**：
    - 处理SOCKS4协议的连接请求。
  - **Socks5.go**：
    - 处理SOCKS5协议的连接请求。
  - **Server.go**：
    - 负责启动SOCKS服务器并监听请求。

- **配置模块（pkg/proxy/config/）**：
  - **Config.go**：
    - 负责加载、解析和管理配置文件（`config.yaml`），包括端口和其他配置选项。
  - **Cache.go**：
    - 管理缓存配置，控制是否缓存DNS查询结果和代理规则。
  - **DNS.go**：
    - 管理DNS配置，支持自定义DNS服务器。
  - **Proxy.go**：
    - 管理代理服务器配置，支持使用系统代理或自定义代理设置，并定义不走代理的IP地址或域名。
  - **Rules.go**：
    - 管理代理规则，提供接口用于动态更新代理规则并将其持久化到配置文件中。
  - **SSL.go**：
    - 管理SSL/TLS配置，加载和管理CA证书及私钥，控制是否验证客户端证书。

##### 3.2. CA证书管理（pkg/ca）

- **CA.go**：  
  - 负责加载和解析自签名的CA证书和私钥。
  - 提供接口用于初始化CA证书，并在需要时生成新的CA证书。

- **Cert.go**：  
  - 实现为特定主机生成临时证书的逻辑。
  - 使用加载的CA证书和私钥对生成的证书进行签名。

##### 3.3. 日志管理（pkg/logger）

**Logger.go**：实现日志管理系统，根据不同的日志级别进行日志记录。支持的日志级别包括`debug`、`info`、`warning`、`error`。  
主要功能如下：

- **日志级别设置**：根据配置文件或环境变量设置日志记录的详细程度。
- **日志输出**：将日志信息输出到控制台和日志文件，支持不同的输出格式。
- **错误处理**：在不同日志级别下记录错误信息，并可在`debug`模式下记录详细调试信息。
- **性能监控**：支持在日志中记录性能指标，如处理请求的时间等。

##### 3.4. Web管理接口

- **API接口**：
  - `updateRuleHandler`：处理更新代理规则的POST请求，通过JSON格式传递原始主机和新主机的信息，包括端口号的变更。
  - `getRulesHandler`：处理GET请求，返回当前所有代理规则的JSON列表。

- **静态文件**：
  - 提供一个简单的Web界面，用户可以通过浏览器管理代理规则，查看当前代理的状态。

#### 4. 时间表

- **第一周**：项目初始化，设置基础目录结构，编写核心代理逻辑，拆分HTTP和SOCKS模块（`Server.go`, `Config.go`），初步实现日志管理系统。
- **第二周**：实现HTTPS流量的解密与重签名（HTTPS模块，CA模块）。
- **第三周**：开发动态代理规则的API接口，并创建简单的Web管理界面，完善日志记录功能。
- **第四周**：进行项目测试、优化与文档编写。

### 5. 优化建议

##### 5.1. 安全性和隐私考虑

- **HTTPS流量处理**：在解密HTTPS流量后，确保对解密的数据进行适当处理，避免敏感信息泄露。
- **IP白名单/黑名单**：实现IP白名单或黑名单机制，控制哪些客户端可以访问代理服务器。

##### 5.2. 可扩展性

- **模块化设计**：保持代理服务器的模块化结构，以便未来能够轻松添加或替换功能模块。
- **插件系统**：设计插件系统，允许通过插件方式添加新功能，如过滤特定类型的流量或集成额外的认证机制。

##### 5.3. 性能优化

- **并发处理**：实现并发处理机制，确保代理服务器能够高效处理大量请求。
- **负载均衡**：考虑实现负载均衡或分布式代理，帮助在多台服务器上分发流量。

##### 5.4. 测试和持续集成

- **测试覆盖率**：在时间表中加入测试阶段，确保每个功能模块在集成之前都经过充分测试。
- **持续集成**：配置持续集成（CI）系统，自动执行单元测试、集成测试和代码质量检查。

### 6. 未来计划

在完成基本功能后，应考虑以下扩展：

- **支持多端口配置**：允许HTTP和SOCKS监听在不同端口。
- **完善Web管理界面**：增加图形化的管理界面，简化用户操作。