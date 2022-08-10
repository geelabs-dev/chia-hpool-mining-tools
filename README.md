:::info
一个有温度的chia集群挖矿管理工具
:::

NAME='chia-hpool-mining-tool'
VER='v1.0.0 开源版'
Miner='HPool-Miner-Chia v1.5.9 (2)'
Powered='Gee.Labs - 极数实验室'
Mail='mail@gee-labs.com'
Discord='[https://discord.gg/za8gAUGdpT'](https://discord.gg/za8gAUGdpT')
本工具开源发布，欢迎大家二次修改使用，使用中如遇任何问题，请加入Discord官方群组，联系技术人员排查问题

# 名词定义
server机 主控机，也是proxy服务器
miner机 带盘机

# 工具描述
本工具为chia机器接入hpool矿池使用的集群管理工具，解决运维人员日常人工维护工作，拒绝windows误人前程！

## 适用场景：
机房运营大量chia机器分属不同客户，使用不同hpool账号，运维难度大

## 集群架构：
1台server机：运行本工具及hpool-proxy服务
N台miner机：运行chia挖矿服务

## 技术原理：
调用hpool挖矿工具，自动分发给miner机执行使用

## 核心优势：
一键部署所有miner机，初始化、启动、停止等操作；
一键监控所有miner主机运行状态，方便运维人员排查故障；
免安装，无需在mienr机上预先安装任何工具或配置；

## 使用前须知：
本工具仅面向Linux客户端使用；
本工具基于ubuntu-server-20.04开发，其他linux系统兼容性未测试；
server机需开启SSH并启用 root 远程登录权限；
miner机需开启SSH并启用 root 远程登录权限；

# 安装使用
本工具免安装，下载即可使用

如遇权限问题请执行：
```bash
chmod +x chia-tools.sh
```

## 设置配置文件

A账号：11111@qq.com 有5台主机，apikey为 chiaog00-1111-1111-1111-6ce57929bf83
B账号：22222@qq.com 有10台主机，apikey为 2a3ae646c-2222-2222-2222-338c24bbdef
C账号：33333@qq.com 有8台主机，apikey为 2a3ae646c-3333-3333-33333-338c24bbdef

修改config文件夹下config.json配置文件，可参考以下配置：
```bash
{
  "server": {
    "init": "",
    "remark": "chia-control",
    "sshIp": "10.0.0.10",
    "sshPort": "22",
    "sshUser": "root",
    "sshPwd": "Aa987654321"
  },
  "miner": [
    {
      "remark": "11111@qq.com",
      "apikey": "chiaog00-1111-1111-1111-6ce57929bf83",
      "proxy": {"ip": "","port": ""},
      "device": [
        {"sshIp": "10.0.0.11","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.12","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.13","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.14","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.15","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"}
      ]
    },
    {
      "remark": "22222@qq.com",
      "apikey": "2a3ae646c-2222-2222-2222-338c24bbdef",
      "proxy": {
        "ip": "",
        "port": ""
      },
      "device": [
        {"sshIp": "10.0.0.51","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.52","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.53","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.54","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.55","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.56","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.57","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.58","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.59","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.60","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"}
      ]
    },
    {
      "remark": "33333@qq.com",
      "apikey": "2a3ae646c-3333-3333-33333-338c24bbdef",
      "proxy": {
        "ip": "",
        "port": ""
      },
      "device": [
        {"sshIp": "10.0.0.81","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.82","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.83","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.84","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.85","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.86","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.87","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"},
        {"sshIp": "10.0.0.88","sshPort": "22","sshUser": "root","sshPwd": "Aa123456789"}
      ]
    }
  ]
}

```

配置server机必填项：（运行本工具的主机）
:::info
    "remark": "自定义server机名称", 
    "sshIp": "server机内网ip地址",
    "sshPort": "server机ssh端口，默认22，建议使用",
    "sshUser": "server机ssh用户名，默认root，建议使用",
    "sshPwd": "server机ssh密码"
:::

miner机配置必填项：（带盘机）
:::info
"remark": "自定义账户名，建议使用hpool登录邮箱或手机，方便识别",
 "apikey": "登录hpool找到chia挖矿apikey，注意区分新老协议",
{"sshIp": "上述hpool账号下miner机ip","sshPort": "22","sshUser": "root","sshPwd": "ssh密码"}
:::

## 初始化miner机
:::info
执行初始化操作会运行以下功能：
从server机tool目录下载chia-hpool-miner挖矿工具到miner机；
从server机tool目录下载yq工具到miner机，用于生成miner配置文件；

注：执行本操作可能会较长时间，具体时间视内网传输速度决定。
:::

**为一台miner机执行初始化：**
```bash
./chia-tools.sh miner init 192.168.5.123
```
注：ip为miner机ip地址

**为所有miner机执行初始化：**
```bash
./chia-tools.sh miner init
```

注：初始化操作只需要执行一次即可

## 启动miner机


**启动一台miner开始挖矿：**
```bash
./chia-tools.sh miner start 192.168.5.123
```
注：ip为miner机ip地址

**启动所有miner开始挖矿：**
```bash
./chia-tools.sh miner start
```

注：启动后miner会自动挂载磁盘并生成配置，开始挖矿

## 停止miner机

**停止一台miner结束挖矿：**
```bash
./chia-tools.sh miner stop 192.168.5.123
```
注：ip为miner机ip地址

**停止所有miner结束挖矿：**
```bash
./chia-tools.sh miner stop
```


## 重启miner机

**重启一台miner系统：**
```bash
./chia-tools.sh miner reboot 192.168.5.123
```
注：ip为miner机ip地址

**重启所有miner系统：**
```bash
./chia-tools.sh miner reboot
```


## 查询miner机状态
```bash
./chia-tools.sh miner status
```

## 挂载数据磁盘
**为一台miner挂载磁盘：**
```bash
./chia-tools.sh miner stop 192.168.5.123
```
注：ip为miner机ip地址

**为所有miner挂载磁盘：**
```bash
./chia-tools.sh miner stop
```

## 更新hpool-chia挖矿工具
:::info
本工具调用hpool工具挖矿，由于hpool存在不定期更新，如需更新挖矿软件，执行以下操作
:::

更新流程：

1. 停止所有miner挖矿
1. 下载hpool最新版工具，上传至 tool 文件夹 覆盖原有同名文件
1. 执行一次初始化操作
1. 启动所有miner挖矿


# LTS长期支持说明
本工具已列入GeeLabs实验室LTS长期支持计划，我们将持续提供升级技术支持，如果您有更好的建议可与我们联系

联系邮箱：mail@gee-labs.com
Discard：[https://discord.gg/za8gAUGdpT](https://discord.gg/za8gAUGdpT')


# 赞助

您的支持将资助开源矿工生态进步发展！

XCH 赞助地址：xch1gpf8pc6qhnsgt7uwu7yp80k09pwcds3ypc7mkmmtucaezmffxmkq8wt4a7









