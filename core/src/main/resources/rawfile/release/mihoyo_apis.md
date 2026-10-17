# 米游社各个游戏 API

## 米游社账号相关 API

### 二维码登录-请求二维码

- API：https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/fetch
- 请求方式：POST
- 请求头示例参数：

```text
POST /hk4e_cn/combo/panda/qrcode/fetch HTTP/1.1
content-type: text/plain;charset=UTF-8
user-agent: tauri-plugin-http/2.5.7
origin: tauri://localhost
accept: */*
cookie: aliyungf_tc=000de48ca30b10148d1d3966c7c4f7c75bc9eb6508d0165f00c6e0b7ba46f21a; ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; cookie_token=TX18n2rt7fGlXz9nJjx64JHMXntEOfKDemITRbCt; ltuid=348366494; account_id=348366494
host: hk4e-sdk.mihoyo.com
content-length: 60

{"app_id":7,"device":"55f55e7f-55ab-4254-a3b2-08e2673096c4"}
```

- Response 结果

```text
HTTP/1.1 200 OK
Date: Sun, 12 Apr 2026 04:40:46 GMT
Content-Type: application/json
Content-Length: 246
Connection: keep-alive
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 29f115d699df5044:29f115d699df5044:0:1

{"retcode":0,"message":"OK","data":{"url":"https://user.mihoyo.com/qr_code_in_game.html?app_id=7\u0026app_name=%E5%B4%A9%E5%9D%8F%E5%AD%A6%E5%9B%AD2\u0026bbs=false\u0026biz_key=bh2_cn\u0026expire=1776400846\u0026ticket=69db224eb28aac09f1178b76"}}
```

### 二维码登录-轮询

- API：https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/query
- 请求方式：POST
- 请求头示例参数：

```text
POST /hk4e_cn/combo/panda/qrcode/query HTTP/1.1
content-type: text/plain;charset=UTF-8
user-agent: tauri-plugin-http/2.5.7
origin: tauri://localhost
accept: */*
cookie: aliyungf_tc=000de48ca30b10148d1d3966c7c4f7c75bc9eb6508d0165f00c6e0b7ba46f21a; ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; cookie_token=TX18n2rt7fGlXz9nJjx64JHMXntEOfKDemITRbCt; ltuid=348366494; account_id=348366494
host: hk4e-sdk.mihoyo.com
content-length: 96

{"app_id":7,"ticket":"69db224eb28aac09f1178b76","device":"55f55e7f-55ab-4254-a3b2-08e2673096c4"}
```

- Response 的结果

```text
HTTP/1.1 200 OK
Date: Sun, 12 Apr 2026 04:40:48 GMT
Content-Type: application/json
Content-Length: 116
Connection: keep-alive
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 221c804d05da480e:221c804d05da480e:0:1

{"retcode":0,"message":"OK","data":{"stat":"Init","payload":{"proto":"Raw","raw":"","ext":""},"realname_info":null}}
```

- 轮询到二维码登录成功的结果

```text
HTTP/1.1 200 OK
Date: Sun, 12 Apr 2026 04:47:49 GMT
Content-Type: application/json
Content-Length: 195
Connection: keep-alive
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 9647d99a952498c:9647d99a952498c:0:1

{"retcode":0,"message":"OK","data":{"stat":"Confirmed","payload":{"proto":"Account","raw":"{\"uid\":\"348366494\",\"token\":\"wNJtsPMvTFySKK05huhRYiDfnM8kyUUd\"}","ext":""},"realname_info":null}}
```

### 手机号登录-获取验证码

- API：https://passport-api.mihoyo.com/account/ma-cn-verifier/verifier/createLoginCaptcha
- 请求方式：POST
- 请求头示例参数：

```text
POST /account/ma-cn-verifier/verifier/createLoginCaptcha HTTP/1.1
content-type: application/json
referer: https://user.miyoushe.com/
user-agent: Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/2.100.0
x-rpc-aigis:
x-rpc-app_id: bll8iq97cem8
x-rpc-app_version: 2.100.0
x-rpc-client_type: 2
x-rpc-device_fp: 38d8166fd9c2e
x-rpc-device_id: 55f55e7f-55ab-4254-a3b2-08e2673096c4
x-rpc-device_model: EYEJ4I
x-rpc-device_name: YPPWGW7NHGYC
x-rpc-game_biz: hk4e_cn
origin: tauri://localhost
accept: */*
cookie: ltoken=Xmdg2BUcb8dVsyL9nAKHDHdeHaDuLZ5Mw91t2XVf; cookie_token=CztueufTYXw07R0r5mQp6GUyF45i8mSwfbNREsqW; ltuid=433290277; account_id=433290277
host: passport-api.mihoyo.com
content-length: 372

{"area_code":"MLd98yMTwY0y/jgRdlHXLaIm3Xlk6sbyqCZSuppcDETBmsVkDpKd7NBHU0iXEtowE1aq2Oavhw6L/h29fpMfu5W5+blJnXXLwoCEJdr9GlbLCu/5x5OQKUuelRGEmOh5EF36l11POLiDH+cRl7oxB0ojlPylqLzOPprEytbflXY=","mobile":"T+Z/3K6fe4TT6+qXXJs3bRUgRAq7CHDDunI0u6Z2C1E9t3BxMXUxERGx66xyaHBknmYIQbLjCmn697BTDP8xxPd5J//kAziCmLfjx1t+EfGIkOf3O8LYOaHiC4MWRrzq21uBCaA+f/nlhmm7CDxdDsiJKeK5xWWjJCsRkfPYh7Y="}
```

- Response 的结果

```text
HTTP/1.1 200 OK
Date: Sat, 11 Apr 2026 17:57:31 GMT
Content-Type: application/json
Content-Length: 108
Connection: keep-alive
Set-Cookie: aliyungf_tc=3d8330ca6492bd783b1c35353c5a1b5f27b1cf8b9d49ed652c3dc6dc7aacf938; Path=/; HttpOnly
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 582988f2a467da35:582988f2a467da35:0:1

{"retcode":0,"message":"OK","data":{"sent_new":true,"countdown":60,"action_type":"login_by_mobile_captcha"}}
```

### 手机号登录-提交验证码

- API：https://passport-api.mihoyo.com/account/ma-cn-passport/app/loginByMobileCaptcha
- 请求方式：POST
- 请求头示例参数：

```text
POST /account/ma-cn-passport/app/loginByMobileCaptcha HTTP/1.1
content-type: text/plain;charset=UTF-8
user-agent: Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/2.100.0
x-rpc-aigis:
x-rpc-app_id: bll8iq97cem8
x-rpc-app_version: 2.100.0
x-rpc-client_type: 2
x-rpc-device_fp: 38d8166fd9c2e
x-rpc-device_id: 55f55e7f-55ab-4254-a3b2-08e2673096c4
x-rpc-device_model: EYEJ4I
x-rpc-device_name: YPPWGW7NHGYC
origin: tauri://localhost
accept: */*
cookie: aliyungf_tc=3d8330ca6492bd783b1c35353c5a1b5f27b1cf8b9d49ed652c3dc6dc7aacf938; ltoken=Xmdg2BUcb8dVsyL9nAKHDHdeHaDuLZ5Mw91t2XVf; cookie_token=CztueufTYXw07R0r5mQp6GUyF45i8mSwfbNREsqW; ltuid=433290277; account_id=433290277
host: passport-api.mihoyo.com
content-length: 431

{"area_code":"KM+FqofmNMG/SWS/6p/QplyYG/m8NqjQ5jT9Dq94MJCeO9vlmGmLFEZndlQbXxDInDteyLH/hOtWr9qIyBGftgBTFShbegFGUgw4HBkoPYWO0W667pJUExyWxafWCsrBQ81BSqHDi1IYC1ekA55Xlu4a0jDb7wU4M1gNaB58nS8=","mobile":"RLb1qRgTzv/t31kbFH0kFfHAEAOmOOUyqm2qEXUISDtjnb0u5ifLV7shrXx+O9ZCkMaBsOH610BhNIhVmVuTvto5kmZnXG9NSYTAszKHl9MchP3ZWxwHC3p9MsajGO3Q55dEukjggodrmX2XxzWUaeKGZKv1dVFdIXxMhqoIw9U=","action_type":"login_by_mobile_captcha","captcha":"209441"}
```

- Response 结果

```text
HTTP/1.1 200 OK
Date: Sat, 11 Apr 2026 17:58:56 GMT
Content-Type: application/json
Content-Length: 908
Connection: keep-alive
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 43ce11d874823128:43ce11d874823128:0:1

{"retcode":0,"message":"OK","data":{"token":{"token_type":1,"token":"v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y=.CAE="},"user_info":{"aid":"348366494","mid":"0tv0t26wei_mhy","account_name":"","email":"","is_email_verify":0,"area_code":"+86","mobile":"186******85","safe_area_code":"","safe_mobile":"","realname":"**鑫","identity_code":"4****************X","rebind_area_code":"","rebind_mobile":"","rebind_mobile_time":"0","links":[],"country":"","password_time":"0","is_adult":1,"unmasked_email":"","unmasked_email_type":0},"reactivate_info":{"required":false,"ticket":"","deleting_biz_account":false,"reactivate_biz":"","delete_after_days":"0"},"login_ticket":"","new_user":false,"realname_info":{"required":false,"action_type":"","action_ticket":""},"need_realperson":false,"oauth_hw_open_id":""}}
```

### 获取ltoken

- API：https://passport-api.mihoyo.com/account/auth/api/getLTokenBySToken?stoken=v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y%3D.CAE%3D
- 请求方式：GET
- 请求头示例参数：

```text
GET /account/auth/api/getLTokenBySToken?stoken=v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y%3D.CAE%3D HTTP/1.1
cookie: mid=0tv0t26wei_mhy;stoken=v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y=.CAE=;
ds: 1775930337,130790,92715728d03878642e2a72f49891abcf
referer: https://webstatic.mihoyo.com
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.100.0
x-requested-with: com.mihoyo.hyperion
x-rpc-app_version: 2.100.0
x-rpc-client_type: 5
x-rpc-device_fp: 38d8166fd9c2e
x-rpc-device_id: 55f55e7f-55ab-4254-a3b2-08e2673096c4
origin: tauri://localhost
accept: */*
host: passport-api.mihoyo.com
```

- Response 结果

```text
HTTP/1.1 200 OK
Date: Sat, 11 Apr 2026 17:58:57 GMT
Content-Type: application/json
Content-Length: 89
Connection: keep-alive
Set-Cookie: aliyungf_tc=275f0916e507420853b1c7d65529b7a06f20f2399043b44e9b4af8c76be50959; Path=/; HttpOnly
Cache-Control: no-cache
Set-Cookie: ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; Path=/; Domain=mihoyo.com; Max-Age=31536000
Set-Cookie: ltuid=348366494; Path=/; Domain=mihoyo.com; Max-Age=31536000
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 49f51b6fa7fadea:49f51b6fa7fadea:0:1

{"retcode":0,"message":"OK","data":{"ltoken":"osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG"}}
```

### 获取 Cookie Token

- API：https://passport-api.mihoyo.com/account/auth/api/getCookieAccountInfoBySToken?stoken=v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y%3D.CAE%3D
- 请求方式：GET
- 请求头示例参数：

```text
GET /account/auth/api/getCookieAccountInfoBySToken?stoken=v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y%3D.CAE%3D HTTP/1.1
cookie: mid=0tv0t26wei_mhy;stoken=v2_YqKL04AHNpWG4FqdNfm8RZYBsDlt0ZjbTf022GJF8miIg9qS1tD2F4y-nWSNgKCjeaU0KraMa45NE46dwKvNuX_X0jsccKSSlrpMt2qFIukkECHhlItdKkWyGap77Rm-TPbwb__m03EXzDaCY5Y=.CAE=;
ds: 1775930337,101934,bf5d5066f843a7ad82120ef7c86a0ae2
referer: https://webstatic.mihoyo.com
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.100.0
x-requested-with: com.mihoyo.hyperion
x-rpc-app_version: 2.100.0
x-rpc-client_type: 5
x-rpc-device_fp: 38d8166fd9c2e
x-rpc-device_id: 55f55e7f-55ab-4254-a3b2-08e2673096c4
origin: tauri://localhost
accept: */*
host: passport-api.mihoyo.com
```

- Response 结果

```text
HTTP/1.1 200 OK
Date: Sat, 11 Apr 2026 17:58:58 GMT
Content-Type: application/json
Content-Length: 113
Connection: keep-alive
Set-Cookie: aliyungf_tc=8b8e306eeb486f439335206c13baf769b14cb38c520b41e30acecac9000c5e49; Path=/; HttpOnly
Cache-Control: no-cache
Set-Cookie: cookie_token=TX18n2rt7fGlXz9nJjx64JHMXntEOfKDemITRbCt; Path=/; Domain=mihoyo.com; Max-Age=172800
Set-Cookie: account_id=348366494; Path=/; Domain=mihoyo.com; Max-Age=172800
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 16e4fecdb7e1a7db:16e4fecdb7e1a7db:0:1

{"retcode":0,"message":"OK","data":{"uid":"348366494","cookie_token":"TX18n2rt7fGlXz9nJjx64JHMXntEOfKDemITRbCt"}}
```

### 关联的游戏列表

- API：https://api-takumi-record.mihoyo.com/game_record/app/card/wapi/getGameRecordCard?uid=182692936
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/card/api/getGameRecordCard?uid=182692936 HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rpc-device_model: iPad14,1
x-rum-tracestate: app_id=484533,origin=rum
Cookie: stuid=182692936;stoken=v2_aSGSbVo6EGU_eDwOKZEuWebGIgKe2E9--GGOYtXuAeR6xgFni-PILDc5Qw7MHm5F3CCm5aq9PfLLt9FWkA1t9rCxO7hHD2He82Na40tG57q5yyEk1OzCyAtEztIIsHq3ogwYtP4xXDMmzVIYrw==.CAE=;mid=0otk3b2k90_mhy;login_ticket=;
User-Agent: Hyperion/547 CFNetwork/1335.0.3 Darwin/21.6.0
Referer: https://app.mihoyo.com
x-rpc-device_name:
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
x-rpc-csm_source: home
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-channel: appstore
DS: 1774684745,tBmwWa,935c6c6a76651d5719d03f3498a13d78
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-client_type: 1
x-rpc-verify_key: bll8iq97cem8
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
traceparent: 00-b3025e86a15c8789b394739454578070-4ad8931bf0b715a9-01
Accept: */*
Accept-Encoding: gzip, deflate, br
x-rpc-h265_supported: 0
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-b3025e86a15c8789b394739454578070-4ad8931bf0b715a9-01
```

### 米游社 BBS 账号详情

- API：https://bbs-api.miyoushe.com/user/api/getUserFullInfo?uid=182692936
- 请求方式：GET
- 请求头示例：

```text
GET /user/api/getUserFullInfo?uid=182692936 HTTP/1.1
Host: bbs-api.miyoushe.com
x-rum-tracestate: app_id=484533,origin=rum
Cookie: stuid=182692936;stoken=v2_aSGSbVo6EGU_eDwOKZEuWebGIgKe2E9--GGOYtXuAeR6xgFni-PILDc5Qw7MHm5F3CCm5aq9PfLLt9FWkA1t9rCxO7hHD2He82Na40tG57q5yyEk1OzCyAtEztIIsHq3ogwYtP4xXDMmzVIYrw==.CAE=;mid=0otk3b2k90_mhy;login_ticket=;
x-rpc-device_model: iPad14,1
User-Agent: Hyperion/547 CFNetwork/1335.0.3 Darwin/21.6.0
Referer: https://app.mihoyo.com
x-rpc-device_name:
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
x-rpc-csm_source: myself
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-channel: appstore
DS: 1774716085,jgdSB8,e46d6c46dafb9cc9d5e3d2ff8102a0e2
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-client_type: 1
x-rpc-verify_key: bll8iq97cem8
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
traceparent: 00-a573bbefa8bc732914397a9375cea86d-68300ec6c0907268-01
Accept: */*
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rpc-h265_supported: 0
x-rum-traceparent: 00-a573bbefa8bc732914397a9375cea86d-68300ec6c0907268-01
```

### 获取米游社绑定的游戏

- API：https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie
- 请求方式：GET
- 请求头示例：

```text
GET /binding/api/getUserGameRolesByCookie HTTP/1.1
cookie: account_id=348366494;cookie_token=TX18n2rt7fGlXz9nJjx64JHMXntEOfKDemITRbCt;
ds: 1775930339,155010,f5b4a101837f1d13d66038620fbdcd85
referer: https://webstatic.mihoyo.com
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.100.0
x-requested-with: com.mihoyo.hyperion
x-rpc-app_version: 2.100.0
x-rpc-client_type: 5
x-rpc-device_fp: 38d8166fd9c2e
x-rpc-device_id: 55f55e7f-55ab-4254-a3b2-08e2673096c4
origin: tauri://localhost
accept: */*
host: api-takumi.mihoyo.com
```

- Response 结果

```text
HTTP/1.1 200 OK
Date: Sat, 11 Apr 2026 17:58:59 GMT
Content-Type: application/json
Content-Length: 416
Connection: keep-alive
Set-Cookie: aliyungf_tc=2407a4ac1fda61016a28868bb96fb3bf28db9607194ec9d7569dc79f00331353; Path=/; HttpOnly
Cache-Control: no-cache
Set-Cookie: ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; Path=/; Domain=mihoyo.com; Max-Age=31536000
Set-Cookie: ltuid=348366494; Path=/; Domain=mihoyo.com; Max-Age=31536000
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 8b16b13c15eeff0:8b16b13c15eeff0:0:1

{"retcode":0,"message":"OK","data":{"list":[{"game_biz":"hk4e_cn","region":"cn_gf01","game_uid":"250375401","nickname":"狂野的沙滩裤","level":57,"is_chosen":false,"region_name":"天空岛","is_official":true,"unmask":[]},{"game_biz":"hkrpg_cn","region":"prod_gf_cn","game_uid":"111310091","nickname":"\u0026符公子","level":67,"is_chosen":false,"region_name":"星穹列车","is_official":true,"unmask":[]}]}}
```

## 原神相关 API

### 原神 Act Calendar Widget

- API：https://api-takumi-record.mihoyo.com/game_record/app/genshin/aapi/act_calendar/widget
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/genshin/aapi/act_calendar/widget HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1775803207,109163,dbf8d571706875327530f1887f7c3bb8
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-device_model: iPad14,1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_FZPxCrn9_KEpey-6PlTsyv-xBS1rg8jCHmbhoXyJz7UI_uETHLNUtj0-skDCvkbIWNueHwoZ0rW4ShupHj5ziCUWYmlsJ1pFaAjtOsEN_VfIlwbsz6k8lWU2LXdoMWCfGpZpsQGwxIEgGcA3Ow==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-sys_version: 15.7.1
```

### 原神 Widget

- API：https://api-takumi-record.mihoyo.com/game_record/app/genshin/aapi/widget/v2
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/genshin/aapi/widget/v2 HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1775801855,108104,57e991d9ef9c9cf6dbff9d697ee4f92d
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-device_model: iPad14,1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_FZPxCrn9_KEpey-6PlTsyv-xBS1rg8jCHmbhoXyJz7UI_uETHLNUtj0-skDCvkbIWNueHwoZ0rW4ShupHj5ziCUWYmlsJ1pFaAjtOsEN_VfIlwbsz6k8lWU2LXdoMWCfGpZpsQGwxIEgGcA3Ow==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-sys_version: 15.7.1
```

### 实时便笺

- API：https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote?role_id=109050292&server=cn_gf01
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/genshin/api/dailyNote?server=cn_gf01&role_id=109050292 HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rum-tracestate: app_id=484533,origin=rum
x-rpc-tool_verison: v6.4.2-gr-cn
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
Cookie: ltmid_v2=0otk3b2k90_mhy; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid_v2=182692936; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; acw_tc=2f6fc15117746847461456835e00880a3a8d1c75becfda7a347692f277e9cc; aliyungf_tc=808b879f03e0cb7daa92f1064383c27fc65d24768e62045cd1c4b57e78c46001; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
Referer: https://webstatic.mihoyo.com/
x-rpc-page: v6.4.2-gr-cn_#/ys
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://webstatic.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
DS: 1774684750,133817,3e707c2562d3b9270fcff5822eadd94a
x-rpc-client_type: 5
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
traceparent: 00-c4d69f98adc7106bbf8e5b6278984185-8191befb9a4ce266-01
Accept: application/json, text/plain, */*
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-c4d69f98adc7106bbf8e5b6278984185-8191befb9a4ce266-01
```

### 角色列表

- API：https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/character/list
- 请求方式：POST
- 请求示例参数：

```json
{
  "server": "cn_gf01",
  "role_id": "109050292",
  "sort_type": 1
}
```

- 请求头示例参数：

```text
POST /game_record/app/genshin/api/character/list HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rum-tracestate: app_id=484533,origin=rum
x-rpc-tool_verison: v6.4.2-gr-cn
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; acw_tc=2f6fc15117746847461456835e00880a3a8d1c75becfda7a347692f277e9cc; aliyungf_tc=808b879f03e0cb7daa92f1064383c27fc65d24768e62045cd1c4b57e78c46001; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
Referer: https://webstatic.mihoyo.com/
x-rpc-page: v6.4.2-gr-cn_#/ys/role/all
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://webstatic.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Content-Length: 56
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
DS: 1774684764,133828,99524001b3594ef57dcf5c6ae77e0b2d
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-client_type: 5
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
traceparent: 00-d42e3cc305543f587087d154622921ce-be270e12e249d64f-01
Content-Type: application/json;charset=utf-8
Accept: application/json, text/plain, */*
x-rpc-sys_version: 15.7.1
Accept-Encoding: gzip, deflate, br
x-rum-traceparent: 00-d42e3cc305543f587087d154622921ce-be270e12e249d64f-01
```

### 角色详情

- API：https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/character/detail
- 请求方式：POST
- 请求示例参数：

```json
{
  "role_id": "109050292",
  "server": "cn_gf01",
  "character_ids": ["10000125"]
}
```

- 请求头示例参数：

```text
POST /game_record/app/genshin/api/character/detail HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rum-tracestate: app_id=484533,origin=rum
x-rpc-tool_verison: v6.4.2-gr-cn
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; acw_tc=2f6fc15117746847461456835e00880a3a8d1c75becfda7a347692f277e9cc; aliyungf_tc=808b879f03e0cb7daa92f1064383c27fc65d24768e62045cd1c4b57e78c46001; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
Referer: https://webstatic.mihoyo.com/
x-rpc-page: v6.4.2-gr-cn_#/ys/role/detail/10000125
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://webstatic.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Content-Length: 71
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
DS: 1774684798,133854,97006690c6d4e5cb6812301991c5382e
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-client_type: 5
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
traceparent: 00-8eaded8c7439c0c74d44def19c7c5a25-45f7bc79c1007c82-01
Content-Type: application/json;charset=utf-8
Accept: application/json, text/plain, */*
x-rpc-sys_version: 15.7.1
Accept-Encoding: gzip, deflate, br
x-rum-traceparent: 00-8eaded8c7439c0c74d44def19c7c5a25-45f7bc79c1007c82-01
```

### 养成材料计算

- API：https://api-takumi.mihoyo.com/event/e20200928calculate/v3/batch_compute
- 请求方式：POST
- 满级天赋计算请求：
  note: 如果不想所有技能都满级，可以将 level_target 改到指定数值
- 请求示例参数：

```json
{
  "items": [
    {
      "avatar_id": 10000122,
      "avatar_level_current": 1,
      "avatar_level_target": 90,
      "element_attr_id": 4,
      "skill_list": [
        {
          "id": 12231,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12232,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12239,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12221,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12222,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12223,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12225,
          "level_current": 1,
          "level_target": 1
        }
      ],
      "from_user_sync": false
    },
    {
      "avatar_id": 10000123,
      "avatar_level_current": 1,
      "avatar_level_target": 90,
      "element_attr_id": 1,
      "skill_list": [
        {
          "id": 12331,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12332,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12339,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12321,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12322,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12323,
          "level_current": 1,
          "level_target": 1
        }
      ],
      "from_user_sync": false
    },
    {
      "avatar_id": 10000119,
      "avatar_level_current": 1,
      "avatar_level_target": 90,
      "element_attr_id": 4,
      "skill_list": [
        {
          "id": 11931,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 11932,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 11939,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 11921,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 11922,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 11923,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 11925,
          "level_current": 1,
          "level_target": 1
        }
      ],
      "from_user_sync": false
    },
    {
      "avatar_id": 10000120,
      "avatar_level_current": 1,
      "avatar_level_target": 90,
      "element_attr_id": 5,
      "skill_list": [
        {
          "id": 12031,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12032,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12039,
          "level_current": 1,
          "level_target": 10
        },
        {
          "id": 12021,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12022,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12023,
          "level_current": 1,
          "level_target": 1
        },
        {
          "id": 12025,
          "level_current": 1,
          "level_target": 1
        }
      ],
      "from_user_sync": false
    }
  ],
  "lang": "zh-cn",
  "region": "cn_gf01",
  "uid": "109050292"
}
```

- 请求头示例参数：

```text
POST /event/e20200928calculate/v3/batch_compute HTTP/1.1
Host: api-takumi.mihoyo.com
Accept: application/json, text/plain, */*
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-cal_type: 1
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
Content-Type: application/json;charset=utf-8
Origin: https://act.mihoyo.com
Content-Length: 1895
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0
Referer: https://act.mihoyo.com/
x-rpc-lrsag:
x-rpc-stat_platform: iOS
Cookie: ltmid_v2=0otk3b2k90_mhy; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid_v2=182692936; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; mi18nLang=zh-cn; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0; aliyungf_tc=a9583c1b8013dc125354aff35c41e4750f5982eb34b6ba5d20e7a9a1cd40e6c6
Connection: keep-alive
```

## 崩坏：星穹铁道相关 API

### 崩坏：星穹铁道 Act Calender Widget

- API：https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/aapi/get_act_calender_widget
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/hkrpg/aapi/get_act_calender_widget HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1775803086,109068,5333e77414b9298ab108b3bd40a0e80b
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_FZPxCrn9_KEpey-6PlTsyv-xBS1rg8jCHmbhoXyJz7UI_uETHLNUtj0-skDCvkbIWNueHwoZ0rW4ShupHj5ziCUWYmlsJ1pFaAjtOsEN_VfIlwbsz6k8lWU2LXdoMWCfGpZpsQGwxIEgGcA3Ow==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-device_model: iPad14,1
```

### 崩坏：星穹铁道 Widget

- API：https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/aapi/widget
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/hkrpg/aapi/widget HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1775801855,108104,57e991d9ef9c9cf6dbff9d697ee4f92d
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_FZPxCrn9_KEpey-6PlTsyv-xBS1rg8jCHmbhoXyJz7UI_uETHLNUtj0-skDCvkbIWNueHwoZ0rW4ShupHj5ziCUWYmlsJ1pFaAjtOsEN_VfIlwbsz6k8lWU2LXdoMWCfGpZpsQGwxIEgGcA3Ow==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-device_model: iPad14,1
```

### 实时便笺：

- API：https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/note?server=prod_gf_cn&role_id=102731382
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/hkrpg/api/note?server=prod_gf_cn&role_id=102731382 HTTP/1.1
Host: api-takumi-record.mihoyo.com
Cookie: _ga=GA1.2.1391720589.1774675650; _gat=1; _gid=GA1.2.1979297185.1774675650; ltmid_v2=0otk3b2k90_mhy; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid_v2=182692936; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; acw_tc=781bad5717746836713651154e0097c32b8042d02176025b67f72561507555; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; mi18nLang=zh-cn; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0; aliyungf_tc=a803a80b72c3ee24024e1a586b0e1f22e9e2c9fb740cc6ebdc0206faf6a94309
Connection: keep-alive
Accept: application/json, text/plain, */*
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-client_type: 5
x-rpc-device_fp: 38d815eefa162
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rpc-tool_verison: v4.1.1
Origin: https://webstatic.mihoyo.com
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0
x-rpc-page: v4.1.1_#/rpg
x-rpc-app_version: 2.102.0
Referer: https://webstatic.mihoyo.com/
x-rpc-platform: 5
DS: 1774683680,132979,3f652a711ff24d3ed6288f2583ee994a
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
```

### 角色列表

- API：https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/avatar/basic?rolePageAccessNotAllowed=&role_id=102731382&server=prod_gf_cn
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/hkrpg/api/avatar/basic?rolePageAccessNotAllowed=&role_id=102731382&server=prod_gf_cn HTTP/1.1
Host: api-takumi-record.mihoyo.com
Cookie: _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; acw_tc=781bad5717746836713651154e0097c32b8042d02176025b67f72561507555; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; mi18nLang=zh-cn; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0; aliyungf_tc=a803a80b72c3ee24024e1a586b0e1f22e9e2c9fb740cc6ebdc0206faf6a94309
Connection: keep-alive
Accept: application/json, text/plain, */*
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-client_type: 5
x-rpc-device_fp: 38d815eefa162
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rpc-tool_verison: v4.1.1
Origin: https://webstatic.mihoyo.com
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0
x-rpc-page: v4.1.1_#/rpg/roles
x-rpc-app_version: 2.102.0
Referer: https://webstatic.mihoyo.com/
x-rpc-platform: 5
DS: 1774683775,133054,cd95b156d2d634a3b26079adea02708e
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
```

### 角色详情列表

- API：https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/avatar/info?need_wiki=true&role_id=102731382&server=prod_gf_cn&id=8008
- 请求方式：GET
- 请求头示例参数：

```text
GET /game_record/app/hkrpg/api/avatar/info?need_wiki=true&role_id=102731382&server=prod_gf_cn&id=8008 HTTP/1.1
Host: api-takumi-record.mihoyo.com
Cookie: _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; acw_tc=781bad5717746836713651154e0097c32b8042d02176025b67f72561507555; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; mi18nLang=zh-cn; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0; aliyungf_tc=a803a80b72c3ee24024e1a586b0e1f22e9e2c9fb740cc6ebdc0206faf6a94309
Connection: keep-alive
Accept: application/json, text/plain, */*
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-client_type: 5
x-rpc-device_fp: 38d815eefa162
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rpc-tool_verison: v4.1.1
Origin: https://webstatic.mihoyo.com
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0
x-rpc-page: v4.1.1_#/rpg/role
x-rpc-app_version: 2.102.0
Referer: https://webstatic.mihoyo.com/
x-rpc-platform: 5
DS: 1774683818,133087,3f71f0853bc933cfcd785343528751f1
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
```

### 角色养成计算

- API：https://api-takumi.mihoyo.com/event/rpgcalc/compute?game=hkrpg
- 请求方式：POST
- 请求头示例参数：

```text
POST /event/rpgcalc/compute?game=hkrpg HTTP/1.1
Host: api-takumi.mihoyo.com
Content-Type: application/json
Origin: https://webstatic.mihoyo.com
Accept-Encoding: gzip, deflate, br
Cookie: ltmid_v2=0otk3b2k90_mhy; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid_v2=182692936; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; mi18nLang=zh-cn; _ga=GA1.1.1391720589.1774675650; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0; _gat_gtag_UA_146776247_4=1; _gid=GA1.2.1979297185.1774675650; aliyungf_tc=a9583c1b8013dc125354aff35c41e4750f5982eb34b6ba5d20e7a9a1cd40e6c6
Connection: keep-alive
Accept: application/json, text/plain, */*
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0
Referer: https://webstatic.mihoyo.com/
Content-Length: 1050
Accept-Language: zh-CN,zh-Hans;q=0.9
```

- 请求示例参数：
  note：如果不想行迹满级，可以将target_level改到指定的数值即可

```json
{
  "game": "hkrpg",
  "avatar": {
    "item_id": "1510",
    "cur_level": 1,
    "target_level": 80
  },
  "equipment": {
    "item_id": "23060",
    "cur_level": 1,
    "target_level": 80
  },
  "skill_list": [
    {
      "item_id": "1510001",
      "cur_level": 1,
      "target_level": 6
    },
    {
      "item_id": "1510002",
      "cur_level": 1,
      "target_level": 10
    },
    {
      "item_id": "1510003",
      "cur_level": 1,
      "target_level": 10
    },
    {
      "item_id": "1510004",
      "cur_level": 1,
      "target_level": 10
    },
    {
      "item_id": "1510101",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510102",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510103",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510201",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510202",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510203",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510204",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510205",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510206",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510207",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510208",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510209",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1510210",
      "cur_level": 1,
      "target_level": 1
    }
  ],
  "lang": "zh-cn",
  "uid": "102731382",
  "region": "prod_gf_cn"
}
```

- Response
```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "avatar_consume": [
      {
        "item_id": "2",
        "item_name": "信用点",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/25fc899824a6e927e954e899d9f35824.png",
        "num": 888000,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/204/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "0",
        "item_purpose": "通用货币",
        "item_desc": "星际和平公司与客户结算时使用的货币，如今已成为太空旅行的硬通货。",
        "item_bg_desc": "<i>「人们奔波、争斗、贸易，为的不过是个终端里显示的数字。但真正珍贵之物，公司的数字是买不到的。」</i>"
      },
      {
        "item_id": "213",
        "item_name": "漫游指南",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/526a847e3925cab279eb07ad189844f0.png",
        "num": 290,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/130/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1010",
        "item_purpose": "角色经验材料",
        "item_desc": "角色的经验材料，可以获得20000点角色经验。",
        "item_bg_desc": "跨越诸界必备的冒险丛书。按下阅读键，充满磁性的声音将以你能听懂的语言讲述知名冒险家们在不同世界间的传奇经历，以及他们在各个星球上获得的珍贵智慧。\\n\\n<i>「漫游指南全新书系《星际美食烹饪导览》开售在即，敬请支持。」</i>\\n<i>「投稿请接入博识学会联觉信标23θ联络员，稿酬可以以您接受的任何形式支付。」</i>"
      },
      {
        "item_id": "110432",
        "item_name": "明辉日珥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/388aa2e532a3db95562b9714b6cae64b.png",
        "num": 65,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6257/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1100",
        "item_purpose": "角色晋阶材料",
        "item_desc": "正阳狮鹫遗落的异型头冠，火属性角色的晋升素材。",
        "item_bg_desc": "在某个明媚的童话里，吉奥里亚曾求取夜月的光芒，以助创生。艾格勒回绝了劲敌的请托，却又悄然注视，将日耀般的目光洒向大地。\\n\\n<i>「正阳与夜月的共舞，带来一场完美的日食。」</i>"
      },
      {
        "item_id": "116003",
        "item_name": "梦现管锥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/dd4a42d14804c7a7a29aaf94c170beda.png",
        "num": 15,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6859/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的高级材料。",
        "item_bg_desc": "所有值得被严肃对待的故事，都共享同一个主题：「人如何渡过只此一次的人生。」\\n生命是如此短暂，纵是圣者贤人也免不了被突兀地抛掷在人世间，毫无准备地经历一段人生。也因此，人们总也无法很好地渡过一生，难免有遗憾、难免有虚度。\\n但好在我们有故事。在故事中，创作者与阅读者得以共享另一段人生；在故事中，人的生命得以被持续地延长；在故事中，我们在有限的囚笼中抵达不朽。\\n\\n<i>「有了故事，我们得以活上千次万次。」</i>"
      },
      {
        "item_id": "116002",
        "item_name": "造梦蘸钢",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/87966547e16cc90bb53c72b88356d5e2.png",
        "num": 15,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6858/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的普通材料。",
        "item_bg_desc": "还记得那个历史掌故吗？军官指着揭露暴行的画作质问道：「这是你画的吗？」\\n画家笑着回答：「不，这是你们画的。」\\n一切试图表现现实的艺术，都不能临摹现实。因为现实粗浅的表象无法涵盖其非物质的深刻意涵。\\n就像一位死去的战士，如果你只去临摹遗容，那便只是世间无数死者中平凡的另一个。但你若在现实之上探索，找到那些肉眼不可见的崇高、勇气、愤怒、不甘，那才算是真正贴近了属于这位战士的现实。\\n唯有那样，人们才会知道，这位战士并不只是世间无数死者中平凡的另一个，此人曾使有山、有水、有房屋的地方，也能有人烟。\\n\\n<i>「有了故事，我们得以与邪恶对抗。」</i>"
      },
      {
        "item_id": "116001",
        "item_name": "童真蜡笔",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/593c5c20d2c4cab9e4cb4c7f9c36a38d.png",
        "num": 15,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6857/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的简单材料。",
        "item_bg_desc": "在混沌未分的荒原上，一位母亲问她的孩子：「是不是你弄坏了你爸的弓箭？」那孩子回答：「不是的，肯定是别人弄坏的。」\\n母亲生气地说：「我们的山洞里根本就没来过别人。如果不是你弄坏的，就只能是我了。」孩子继续回答：「是小魔怪干的。我亲眼看到它弄坏了爸爸的弓箭，但只有小孩子才看得到小魔怪，所以妈妈没看见。」\\n母亲被气笑了：「那你倒是说说看，这小魔怪为什么要弄坏你爸的弓箭？」孩子坦然地说：「父亲踩坏了它的巢穴吧。你们大人看不见小魔怪，很容易弄坏他们的巢穴。」\\n这段对话很可能发生过，但也可能从未发生过。但不管怎么说，它所指涉的真理确凿无疑——最初的故事诞生于孩童的幻想。\\n此后亿万年间，这些幻想将会持续不断地改变这个世界。\\n\\n<i>「有了故事，我们得以从现实逃脱。」</i>"
      }
    ],
    "skill_consume": [
      {
        "item_id": "2",
        "item_name": "信用点",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/25fc899824a6e927e954e899d9f35824.png",
        "num": 3000000,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/204/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "0",
        "item_purpose": "通用货币",
        "item_desc": "星际和平公司与客户结算时使用的货币，如今已成为太空旅行的硬通货。",
        "item_bg_desc": "<i>「人们奔波、争斗、贸易，为的不过是个终端里显示的数字。但真正珍贵之物，公司的数字是买不到的。」</i>"
      },
      {
        "item_id": "110293",
        "item_name": "银河沙盘",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/9a0521b37c96135615d5f2d82d525676.png",
        "num": 139,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7691/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "由一位领航员遍观寰宇绘出的银河沙盘。可大幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "先驱者绘下的图景包罗万象，拟造的沙盘足以将整个星海囊括入怀。\\n后来者便以此为旅途之始，将沙盘装入随身的手提包，依傍前人的足迹前行。\\n直到星星陨落，她回头，才发现一路聚散离合，她已行至众人之前，她正踩在连沙盘也未记述的星间。\\n\\n<i>「寰宇的意义，必定在寰宇之外。」</i>"
      },
      {
        "item_id": "110292",
        "item_name": "星系框架",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/15b105333801129bb7f9f23e19f0eca6.png",
        "num": 69,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7692/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "星际航行相关专业用以进阶研究的星系框架。可中幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "星际航行动力学的课堂上，浩瀚的星海被丈量出几寸几尺，不落的星子也成了框架里规格参数各异的零部件。\\n从此远方站满分数与考核，浪漫需要写成白纸黑字的答案。\\n看来求学的旅途比想象中更需要热爱的力气。\\n\\n<i>「这个星系框架做得非常漂亮，我是说，我该给你一个优秀。」</i>"
      },
      {
        "item_id": "110291",
        "item_name": "天体模型",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/a635e84ab51a5064b054e6337110a8c7.png",
        "num": 18,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7693/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "适合天体爱好者了解学习的初级模型。可小幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "年少时于手中把玩的模型，也曾被热爱与向往捂出炙烫的温度。\\n尽管它工艺简单、材质普通，却足以让孩童相信，无垠的宇宙也不过掌中小小的圆球。\\n它向少年人描摹了寰宇的一角，又永远被留在了童年的床头。\\n\\n<i>「后来我迈向银河，远离家乡…列车的舷窗里，故土果然变成了小小的模样。」</i>"
      },
      {
        "item_id": "241",
        "item_name": "命运的足迹",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/050a40252a73e06782ca0865a9dad6c3.png",
        "num": 8,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/405/detail?bbs_presentation_style=no_header",
        "rarity": "5",
        "item_group": "1300",
        "item_purpose": "行迹材料",
        "item_desc": "行迹升级的高阶素材。",
        "item_bg_desc": "一次又一次的败北成就了你的胜利，一步又一步的前进让你抵达了命运的拐点。"
      },
      {
        "item_id": "110508",
        "item_name": "灭流绝溢的缄默",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/b661cd64e37fcb84f127cfe981331ac1.png",
        "num": 12,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6555/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1310",
        "item_purpose": "行迹材料",
        "item_desc": "行迹升级的高阶素材。",
        "item_bg_desc": "无人曾忆起，寰宇刹那间的寂静。思绪之声消融，一切形状被识认为相通的图素，被逆模因的织网捕获，化作唯一解答的推演。\\n直至它不再「言语」。\\n\\n<i>「核心▀▄决断▀▄█循环▄█▀个体▄我▀▄」</i>"
      },
      {
        "item_id": "116003",
        "item_name": "梦现管锥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/dd4a42d14804c7a7a29aaf94c170beda.png",
        "num": 58,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6859/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的高级材料。",
        "item_bg_desc": "所有值得被严肃对待的故事，都共享同一个主题：「人如何渡过只此一次的人生。」\\n生命是如此短暂，纵是圣者贤人也免不了被突兀地抛掷在人世间，毫无准备地经历一段人生。也因此，人们总也无法很好地渡过一生，难免有遗憾、难免有虚度。\\n但好在我们有故事。在故事中，创作者与阅读者得以共享另一段人生；在故事中，人的生命得以被持续地延长；在故事中，我们在有限的囚笼中抵达不朽。\\n\\n<i>「有了故事，我们得以活上千次万次。」</i>"
      },
      {
        "item_id": "116002",
        "item_name": "造梦蘸钢",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/87966547e16cc90bb53c72b88356d5e2.png",
        "num": 56,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6858/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的普通材料。",
        "item_bg_desc": "还记得那个历史掌故吗？军官指着揭露暴行的画作质问道：「这是你画的吗？」\\n画家笑着回答：「不，这是你们画的。」\\n一切试图表现现实的艺术，都不能临摹现实。因为现实粗浅的表象无法涵盖其非物质的深刻意涵。\\n就像一位死去的战士，如果你只去临摹遗容，那便只是世间无数死者中平凡的另一个。但你若在现实之上探索，找到那些肉眼不可见的崇高、勇气、愤怒、不甘，那才算是真正贴近了属于这位战士的现实。\\n唯有那样，人们才会知道，这位战士并不只是世间无数死者中平凡的另一个，此人曾使有山、有水、有房屋的地方，也能有人烟。\\n\\n<i>「有了故事，我们得以与邪恶对抗。」</i>"
      },
      {
        "item_id": "116001",
        "item_name": "童真蜡笔",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/593c5c20d2c4cab9e4cb4c7f9c36a38d.png",
        "num": 41,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6857/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的简单材料。",
        "item_bg_desc": "在混沌未分的荒原上，一位母亲问她的孩子：「是不是你弄坏了你爸的弓箭？」那孩子回答：「不是的，肯定是别人弄坏的。」\\n母亲生气地说：「我们的山洞里根本就没来过别人。如果不是你弄坏的，就只能是我了。」孩子继续回答：「是小魔怪干的。我亲眼看到它弄坏了爸爸的弓箭，但只有小孩子才看得到小魔怪，所以妈妈没看见。」\\n母亲被气笑了：「那你倒是说说看，这小魔怪为什么要弄坏你爸的弓箭？」孩子坦然地说：「父亲踩坏了它的巢穴吧。你们大人看不见小魔怪，很容易弄坏他们的巢穴。」\\n这段对话很可能发生过，但也可能从未发生过。但不管怎么说，它所指涉的真理确凿无疑——最初的故事诞生于孩童的幻想。\\n此后亿万年间，这些幻想将会持续不断地改变这个世界。\\n\\n<i>「有了故事，我们得以从现实逃脱。」</i>"
      }
    ],
    "equipment_consume": [
      {
        "item_id": "2",
        "item_name": "信用点",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/25fc899824a6e927e954e899d9f35824.png",
        "num": 883000,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/204/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "0",
        "item_purpose": "通用货币",
        "item_desc": "星际和平公司与客户结算时使用的货币，如今已成为太空旅行的硬通货。",
        "item_bg_desc": "<i>「人们奔波、争斗、贸易，为的不过是个终端里显示的数字。但真正珍贵之物，公司的数字是买不到的。」</i>"
      },
      {
        "item_id": "223",
        "item_name": "提纯以太",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/b9228080c5ca7dcee14afa7b3de6db6e.png",
        "num": 166,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/522/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1020",
        "item_purpose": "光锥经验材料",
        "item_desc": "光锥的强化材料，可以获得6000点光锥经验。",
        "item_bg_desc": "一罐经由特殊技术精炼而成的以太。\\n\\n<i>「忆庭盼望重现往日的辉煌，但那是由他们所选择的『往日辉煌』，明白吗？」</i>"
      },
      {
        "item_id": "110293",
        "item_name": "银河沙盘",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/9a0521b37c96135615d5f2d82d525676.png",
        "num": 15,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7691/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "由一位领航员遍观寰宇绘出的银河沙盘。可大幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "先驱者绘下的图景包罗万象，拟造的沙盘足以将整个星海囊括入怀。\\n后来者便以此为旅途之始，将沙盘装入随身的手提包，依傍前人的足迹前行。\\n直到星星陨落，她回头，才发现一路聚散离合，她已行至众人之前，她正踩在连沙盘也未记述的星间。\\n\\n<i>「寰宇的意义，必定在寰宇之外。」</i>"
      },
      {
        "item_id": "110292",
        "item_name": "星系框架",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/15b105333801129bb7f9f23e19f0eca6.png",
        "num": 12,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7692/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "星际航行相关专业用以进阶研究的星系框架。可中幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "星际航行动力学的课堂上，浩瀚的星海被丈量出几寸几尺，不落的星子也成了框架里规格参数各异的零部件。\\n从此远方站满分数与考核，浪漫需要写成白纸黑字的答案。\\n看来求学的旅途比想象中更需要热爱的力气。\\n\\n<i>「这个星系框架做得非常漂亮，我是说，我该给你一个优秀。」</i>"
      },
      {
        "item_id": "110291",
        "item_name": "天体模型",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/a635e84ab51a5064b054e6337110a8c7.png",
        "num": 4,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7693/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "适合天体爱好者了解学习的初级模型。可小幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "年少时于手中把玩的模型，也曾被热爱与向往捂出炙烫的温度。\\n尽管它工艺简单、材质普通，却足以让孩童相信，无垠的宇宙也不过掌中小小的圆球。\\n它向少年人描摹了寰宇的一角，又永远被留在了童年的床头。\\n\\n<i>「后来我迈向银河，远离家乡…列车的舷窗里，故土果然变成了小小的模样。」</i>"
      },
      {
        "item_id": "116003",
        "item_name": "梦现管锥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/dd4a42d14804c7a7a29aaf94c170beda.png",
        "num": 14,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6859/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的高级材料。",
        "item_bg_desc": "所有值得被严肃对待的故事，都共享同一个主题：「人如何渡过只此一次的人生。」\\n生命是如此短暂，纵是圣者贤人也免不了被突兀地抛掷在人世间，毫无准备地经历一段人生。也因此，人们总也无法很好地渡过一生，难免有遗憾、难免有虚度。\\n但好在我们有故事。在故事中，创作者与阅读者得以共享另一段人生；在故事中，人的生命得以被持续地延长；在故事中，我们在有限的囚笼中抵达不朽。\\n\\n<i>「有了故事，我们得以活上千次万次。」</i>"
      },
      {
        "item_id": "116002",
        "item_name": "造梦蘸钢",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/87966547e16cc90bb53c72b88356d5e2.png",
        "num": 20,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6858/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的普通材料。",
        "item_bg_desc": "还记得那个历史掌故吗？军官指着揭露暴行的画作质问道：「这是你画的吗？」\\n画家笑着回答：「不，这是你们画的。」\\n一切试图表现现实的艺术，都不能临摹现实。因为现实粗浅的表象无法涵盖其非物质的深刻意涵。\\n就像一位死去的战士，如果你只去临摹遗容，那便只是世间无数死者中平凡的另一个。但你若在现实之上探索，找到那些肉眼不可见的崇高、勇气、愤怒、不甘，那才算是真正贴近了属于这位战士的现实。\\n唯有那样，人们才会知道，这位战士并不只是世间无数死者中平凡的另一个，此人曾使有山、有水、有房屋的地方，也能有人烟。\\n\\n<i>「有了故事，我们得以与邪恶对抗。」</i>"
      },
      {
        "item_id": "116001",
        "item_name": "童真蜡笔",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/593c5c20d2c4cab9e4cb4c7f9c36a38d.png",
        "num": 20,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6857/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的简单材料。",
        "item_bg_desc": "在混沌未分的荒原上，一位母亲问她的孩子：「是不是你弄坏了你爸的弓箭？」那孩子回答：「不是的，肯定是别人弄坏的。」\\n母亲生气地说：「我们的山洞里根本就没来过别人。如果不是你弄坏的，就只能是我了。」孩子继续回答：「是小魔怪干的。我亲眼看到它弄坏了爸爸的弓箭，但只有小孩子才看得到小魔怪，所以妈妈没看见。」\\n母亲被气笑了：「那你倒是说说看，这小魔怪为什么要弄坏你爸的弓箭？」孩子坦然地说：「父亲踩坏了它的巢穴吧。你们大人看不见小魔怪，很容易弄坏他们的巢穴。」\\n这段对话很可能发生过，但也可能从未发生过。但不管怎么说，它所指涉的真理确凿无疑——最初的故事诞生于孩童的幻想。\\n此后亿万年间，这些幻想将会持续不断地改变这个世界。\\n\\n<i>「有了故事，我们得以从现实逃脱。」</i>"
      }
    ],
    "user_owns_materials": {
      "116003": 9,
      "223": 581,
      "241": 13,
      "213": 1541,
      "116001": 3525,
      "110292": 40,
      "2": 25662554,
      "116002": 13
    },
    "need_get_materials": [
      {
        "item_id": "110432",
        "item_name": "明辉日珥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/388aa2e532a3db95562b9714b6cae64b.png",
        "num": 65,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6257/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1100",
        "item_purpose": "角色晋阶材料",
        "item_desc": "正阳狮鹫遗落的异型头冠，火属性角色的晋升素材。",
        "item_bg_desc": "在某个明媚的童话里，吉奥里亚曾求取夜月的光芒，以助创生。艾格勒回绝了劲敌的请托，却又悄然注视，将日耀般的目光洒向大地。\\n\\n<i>「正阳与夜月的共舞，带来一场完美的日食。」</i>"
      },
      {
        "item_id": "110293",
        "item_name": "银河沙盘",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/9a0521b37c96135615d5f2d82d525676.png",
        "num": 154,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7691/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "由一位领航员遍观寰宇绘出的银河沙盘。可大幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "先驱者绘下的图景包罗万象，拟造的沙盘足以将整个星海囊括入怀。\\n后来者便以此为旅途之始，将沙盘装入随身的手提包，依傍前人的足迹前行。\\n直到星星陨落，她回头，才发现一路聚散离合，她已行至众人之前，她正踩在连沙盘也未记述的星间。\\n\\n<i>「寰宇的意义，必定在寰宇之外。」</i>"
      },
      {
        "item_id": "110292",
        "item_name": "星系框架",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/15b105333801129bb7f9f23e19f0eca6.png",
        "num": 41,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7692/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "星际航行相关专业用以进阶研究的星系框架。可中幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "星际航行动力学的课堂上，浩瀚的星海被丈量出几寸几尺，不落的星子也成了框架里规格参数各异的零部件。\\n从此远方站满分数与考核，浪漫需要写成白纸黑字的答案。\\n看来求学的旅途比想象中更需要热爱的力气。\\n\\n<i>「这个星系框架做得非常漂亮，我是说，我该给你一个优秀。」</i>"
      },
      {
        "item_id": "110291",
        "item_name": "天体模型",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/a635e84ab51a5064b054e6337110a8c7.png",
        "num": 22,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7693/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "适合天体爱好者了解学习的初级模型。可小幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "年少时于手中把玩的模型，也曾被热爱与向往捂出炙烫的温度。\\n尽管它工艺简单、材质普通，却足以让孩童相信，无垠的宇宙也不过掌中小小的圆球。\\n它向少年人描摹了寰宇的一角，又永远被留在了童年的床头。\\n\\n<i>「后来我迈向银河，远离家乡…列车的舷窗里，故土果然变成了小小的模样。」</i>"
      },
      {
        "item_id": "110508",
        "item_name": "灭流绝溢的缄默",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/b661cd64e37fcb84f127cfe981331ac1.png",
        "num": 12,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6555/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1310",
        "item_purpose": "行迹材料",
        "item_desc": "行迹升级的高阶素材。",
        "item_bg_desc": "无人曾忆起，寰宇刹那间的寂静。思绪之声消融，一切形状被识认为相通的图素，被逆模因的织网捕获，化作唯一解答的推演。\\n直至它不再「言语」。\\n\\n<i>「核心▀▄决断▀▄█循环▄█▀个体▄我▀▄」</i>"
      }
    ],
    "can_pay_materials": [
      {
        "item_id": "2",
        "item_name": "信用点",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/25fc899824a6e927e954e899d9f35824.png",
        "num": 4771000,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/204/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "0",
        "item_purpose": "通用货币",
        "item_desc": "星际和平公司与客户结算时使用的货币，如今已成为太空旅行的硬通货。",
        "item_bg_desc": "<i>「人们奔波、争斗、贸易，为的不过是个终端里显示的数字。但真正珍贵之物，公司的数字是买不到的。」</i>"
      },
      {
        "item_id": "213",
        "item_name": "漫游指南",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/526a847e3925cab279eb07ad189844f0.png",
        "num": 290,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/130/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1010",
        "item_purpose": "角色经验材料",
        "item_desc": "角色的经验材料，可以获得20000点角色经验。",
        "item_bg_desc": "跨越诸界必备的冒险丛书。按下阅读键，充满磁性的声音将以你能听懂的语言讲述知名冒险家们在不同世界间的传奇经历，以及他们在各个星球上获得的珍贵智慧。\\n\\n<i>「漫游指南全新书系《星际美食烹饪导览》开售在即，敬请支持。」</i>\\n<i>「投稿请接入博识学会联觉信标23θ联络员，稿酬可以以您接受的任何形式支付。」</i>"
      },
      {
        "item_id": "223",
        "item_name": "提纯以太",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/b9228080c5ca7dcee14afa7b3de6db6e.png",
        "num": 166,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/522/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1020",
        "item_purpose": "光锥经验材料",
        "item_desc": "光锥的强化材料，可以获得6000点光锥经验。",
        "item_bg_desc": "一罐经由特殊技术精炼而成的以太。\\n\\n<i>「忆庭盼望重现往日的辉煌，但那是由他们所选择的『往日辉煌』，明白吗？」</i>"
      },
      {
        "item_id": "110292",
        "item_name": "星系框架",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/15b105333801129bb7f9f23e19f0eca6.png",
        "num": 40,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/7692/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1223",
        "item_purpose": "行迹材料 \\n光锥晋阶材料",
        "item_desc": "星际航行相关专业用以进阶研究的星系框架。可中幅提升<color=#f29e38ff>智识</color>角色的命途行迹。",
        "item_bg_desc": "星际航行动力学的课堂上，浩瀚的星海被丈量出几寸几尺，不落的星子也成了框架里规格参数各异的零部件。\\n从此远方站满分数与考核，浪漫需要写成白纸黑字的答案。\\n看来求学的旅途比想象中更需要热爱的力气。\\n\\n<i>「这个星系框架做得非常漂亮，我是说，我该给你一个优秀。」</i>"
      },
      {
        "item_id": "241",
        "item_name": "命运的足迹",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/050a40252a73e06782ca0865a9dad6c3.png",
        "num": 8,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/405/detail?bbs_presentation_style=no_header",
        "rarity": "5",
        "item_group": "1300",
        "item_purpose": "行迹材料",
        "item_desc": "行迹升级的高阶素材。",
        "item_bg_desc": "一次又一次的败北成就了你的胜利，一步又一步的前进让你抵达了命运的拐点。"
      },
      {
        "item_id": "116003",
        "item_name": "梦现管锥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/dd4a42d14804c7a7a29aaf94c170beda.png",
        "num": 9,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6859/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的高级材料。",
        "item_bg_desc": "所有值得被严肃对待的故事，都共享同一个主题：「人如何渡过只此一次的人生。」\\n生命是如此短暂，纵是圣者贤人也免不了被突兀地抛掷在人世间，毫无准备地经历一段人生。也因此，人们总也无法很好地渡过一生，难免有遗憾、难免有虚度。\\n但好在我们有故事。在故事中，创作者与阅读者得以共享另一段人生；在故事中，人的生命得以被持续地延长；在故事中，我们在有限的囚笼中抵达不朽。\\n\\n<i>「有了故事，我们得以活上千次万次。」</i>"
      },
      {
        "item_id": "116002",
        "item_name": "造梦蘸钢",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/87966547e16cc90bb53c72b88356d5e2.png",
        "num": 13,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6858/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的普通材料。",
        "item_bg_desc": "还记得那个历史掌故吗？军官指着揭露暴行的画作质问道：「这是你画的吗？」\\n画家笑着回答：「不，这是你们画的。」\\n一切试图表现现实的艺术，都不能临摹现实。因为现实粗浅的表象无法涵盖其非物质的深刻意涵。\\n就像一位死去的战士，如果你只去临摹遗容，那便只是世间无数死者中平凡的另一个。但你若在现实之上探索，找到那些肉眼不可见的崇高、勇气、愤怒、不甘，那才算是真正贴近了属于这位战士的现实。\\n唯有那样，人们才会知道，这位战士并不只是世间无数死者中平凡的另一个，此人曾使有山、有水、有房屋的地方，也能有人烟。\\n\\n<i>「有了故事，我们得以与邪恶对抗。」</i>"
      },
      {
        "item_id": "116001",
        "item_name": "童真蜡笔",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/593c5c20d2c4cab9e4cb4c7f9c36a38d.png",
        "num": 76,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6857/detail?bbs_presentation_style=no_header",
        "rarity": "2",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的简单材料。",
        "item_bg_desc": "在混沌未分的荒原上，一位母亲问她的孩子：「是不是你弄坏了你爸的弓箭？」那孩子回答：「不是的，肯定是别人弄坏的。」\\n母亲生气地说：「我们的山洞里根本就没来过别人。如果不是你弄坏的，就只能是我了。」孩子继续回答：「是小魔怪干的。我亲眼看到它弄坏了爸爸的弓箭，但只有小孩子才看得到小魔怪，所以妈妈没看见。」\\n母亲被气笑了：「那你倒是说说看，这小魔怪为什么要弄坏你爸的弓箭？」孩子坦然地说：「父亲踩坏了它的巢穴吧。你们大人看不见小魔怪，很容易弄坏他们的巢穴。」\\n这段对话很可能发生过，但也可能从未发生过。但不管怎么说，它所指涉的真理确凿无疑——最初的故事诞生于孩童的幻想。\\n此后亿万年间，这些幻想将会持续不断地改变这个世界。\\n\\n<i>「有了故事，我们得以从现实逃脱。」</i>"
      }
    ],
    "can_merge_materials": [
      {
        "item_id": "116003",
        "item_name": "梦现管锥",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/dd4a42d14804c7a7a29aaf94c170beda.png",
        "num": 78,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6859/detail?bbs_presentation_style=no_header",
        "rarity": "4",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的高级材料。",
        "item_bg_desc": "所有值得被严肃对待的故事，都共享同一个主题：「人如何渡过只此一次的人生。」\\n生命是如此短暂，纵是圣者贤人也免不了被突兀地抛掷在人世间，毫无准备地经历一段人生。也因此，人们总也无法很好地渡过一生，难免有遗憾、难免有虚度。\\n但好在我们有故事。在故事中，创作者与阅读者得以共享另一段人生；在故事中，人的生命得以被持续地延长；在故事中，我们在有限的囚笼中抵达不朽。\\n\\n<i>「有了故事，我们得以活上千次万次。」</i>"
      },
      {
        "item_id": "116002",
        "item_name": "造梦蘸钢",
        "item_url": "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u47dee/87966547e16cc90bb53c72b88356d5e2.png",
        "num": 78,
        "wiki_url": "https://bbs.mihoyo.com/sr/wiki/content/6858/detail?bbs_presentation_style=no_header",
        "rarity": "3",
        "item_group": "1411",
        "item_purpose": "行迹材料 \\n角色晋阶材料",
        "item_desc": "幻造生物的愿力碎片，强化所需的普通材料。",
        "item_bg_desc": "还记得那个历史掌故吗？军官指着揭露暴行的画作质问道：「这是你画的吗？」\\n画家笑着回答：「不，这是你们画的。」\\n一切试图表现现实的艺术，都不能临摹现实。因为现实粗浅的表象无法涵盖其非物质的深刻意涵。\\n就像一位死去的战士，如果你只去临摹遗容，那便只是世间无数死者中平凡的另一个。但你若在现实之上探索，找到那些肉眼不可见的崇高、勇气、愤怒、不甘，那才算是真正贴近了属于这位战士的现实。\\n唯有那样，人们才会知道，这位战士并不只是世间无数死者中平凡的另一个，此人曾使有山、有水、有房屋的地方，也能有人烟。\\n\\n<i>「有了故事，我们得以与邪恶对抗。」</i>"
      }
    ],
    "coin_id": "2"
  }
}
```

## 绝区零相关 API

### 绝区零 Widget

- API: https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/widget
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/widget HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1775801856,108105,df6e648a0efce71574def1a66592ced2
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_FZPxCrn9_KEpey-6PlTsyv-xBS1rg8jCHmbhoXyJz7UI_uETHLNUtj0-skDCvkbIWNueHwoZ0rW4ShupHj5ziCUWYmlsJ1pFaAjtOsEN_VfIlwbsz6k8lWU2LXdoMWCfGpZpsQGwxIEgGcA3Ow==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-device_model: iPad14,1
```

### 养成材料计算：

- API：https://act-api-takumi.mihoyo.com/event/nap_cultivate_tool/avatar_calc?uid=37716744&region=prod_gf_cn
- 请求方式：POST
- 请求头示例参数：

```text
POST /event/nap_cultivate_tool/avatar_calc?uid=37716744&region=prod_gf_cn HTTP/1.1
Host: act-api-takumi.mihoyo.com
Referer: https://act.mihoyo.com/
Cookie: SERVERCORSID=6a6789f2c24e6fb77363d7f6fc7c39aa|1774684154|1774683928; SERVERID=6a6789f2c24e6fb77363d7f6fc7c39aa|1774684154|1774683928; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; mi18nLang=zh-cn; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0
x-rpc-geetest_ext: {"gameId":8,"page":"v2.6.1_apps-v_#/material-calc/1051","viewSource":3,"actionSource":132}
x-rpc-lang: zh-cn
x-rpc-page: v2.6.1_apps-v_#/material-calc/1051
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
Content-Length: 356
x-rpc-cultivate_source: bbs
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
Accept: application/json, text/plain, */*
Content-Type: application/json
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rpc-is_teaser: 1
x-rpc-platform: 1
```

- 请求示例参数：
  note: 如果不想所有技能都满级，可以将 level 改成指定的数值

```json
{
  "avatar_id": 1061,
  "avatar_level": 60,
  "avatar_current_level": 40,
  "avatar_current_promotes": 4,
  "skills": [
    {
      "skill_type": 0,
      "level": 12,
      "init_level": 7
    },
    {
      "skill_type": 1,
      "level": 12,
      "init_level": 6
    },
    {
      "skill_type": 2,
      "level": 12,
      "init_level": 7
    },
    {
      "skill_type": 3,
      "level": 12,
      "init_level": 7
    },
    {
      "skill_type": 5,
      "level": 7,
      "init_level": 4
    },
    {
      "skill_type": 6,
      "level": 12,
      "init_level": 6
    }
  ],
  "weapon_info": {
    "weapon_id": 13106,
    "weapon_level": 60,
    "weapon_promotes": 0,
    "weapon_init_level": 10
  }
}
```

- Response

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "avatar_consume": [
      {
        "id": 10,
        "cnt": 600000,
        "name": "丁尼",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/c46b44f074463f21c25a29b09f136abe.png",
        "rarity": "B",
        "not_opened": false
      },
      {
        "id": 100231,
        "cnt": 30,
        "name": "先行者认证章",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/a4fa823185b59d2ff47438d56c09bc90.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 300003,
        "cnt": 225,
        "name": "资深调查员记录",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/f0a16ccc3622b6f1206767e98457036c.png",
        "rarity": "A",
        "not_opened": false
      }
    ],
    "weapon_consume": [
      {
        "id": 10,
        "cnt": 320000,
        "name": "丁尼",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/c46b44f074463f21c25a29b09f136abe.png",
        "rarity": "B",
        "not_opened": false
      },
      {
        "id": 101010,
        "cnt": 3,
        "name": "强攻组件",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/266cf22e42e81f4cf106315286cb9ab7.png",
        "rarity": "C",
        "not_opened": false
      },
      {
        "id": 101020,
        "cnt": 26,
        "name": "增强型强攻组件",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/5d808f8098cb2b106573acd87a72dfcb.png",
        "rarity": "B",
        "not_opened": false
      },
      {
        "id": 101030,
        "cnt": 24,
        "name": "特化型强攻组件",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/cbcebc482cf68e9e402a6e980f7f58e5.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 301003,
        "cnt": 159,
        "name": "音擎能源模块",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/dfa35bafaa82d715ffc0d18dace01b16.png",
        "rarity": "A",
        "not_opened": false
      }
    ],
    "skill_consume": [
      {
        "id": 10,
        "cnt": 2646000,
        "name": "丁尼",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/c46b44f074463f21c25a29b09f136abe.png",
        "rarity": "B",
        "not_opened": false
      },
      {
        "id": 100120,
        "cnt": 12,
        "name": "进阶物理芯片",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/7946699d702dcec127661139f878cc4c.png",
        "rarity": "B",
        "not_opened": false
      },
      {
        "id": 100130,
        "cnt": 250,
        "name": "特化物理芯片",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/233bbe23662157567bb2c0fc7d7da9c3.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 100941,
        "cnt": 5,
        "name": "「仓鼠笼」访问器",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/f5833dc4ebed3c351bb51278078b20b5.png",
        "rarity": "S",
        "not_opened": false
      },
      {
        "id": 110003,
        "cnt": 9,
        "name": "终幕舞鞋",
        "icon": "https://act-webstatic.mihoyo.com/game_record/zzzv2/material_icon/material_icon_110003.png",
        "rarity": "S",
        "not_opened": false
      },
      {
        "id": 110502,
        "cnt": 54,
        "name": "高维数据：殷红震慑",
        "icon": "https://act-webstatic.mihoyo.com/game_record/zzzv2/material_icon/material_icon_110502.png",
        "rarity": "A",
        "not_opened": false
      }
    ],
    "coin_id": 10,
    "user_owns_materials": {
      "10": 392711,
      "100941": 1,
      "300003": 109,
      "101010": 2,
      "110502": 30,
      "301003": 71,
      "101020": 6,
      "100120": 21,
      "110003": 2
    },
    "need_get": [
      {
        "id": 10,
        "cnt": 3173289,
        "name": "丁尼",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/c46b44f074463f21c25a29b09f136abe.png",
        "rarity": "B",
        "not_opened": false
      },
      {
        "id": 100130,
        "cnt": 243,
        "name": "特化物理芯片",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/233bbe23662157567bb2c0fc7d7da9c3.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 100231,
        "cnt": 29,
        "name": "先行者认证章",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/a4fa823185b59d2ff47438d56c09bc90.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 100941,
        "cnt": 4,
        "name": "「仓鼠笼」访问器",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/f5833dc4ebed3c351bb51278078b20b5.png",
        "rarity": "S",
        "not_opened": false
      },
      {
        "id": 101030,
        "cnt": 31,
        "name": "特化型强攻组件",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/cbcebc482cf68e9e402a6e980f7f58e5.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 110003,
        "cnt": 7,
        "name": "终幕舞鞋",
        "icon": "https://act-webstatic.mihoyo.com/game_record/zzzv2/material_icon/material_icon_110003.png",
        "rarity": "S",
        "not_opened": false
      },
      {
        "id": 110502,
        "cnt": 24,
        "name": "高维数据：殷红震慑",
        "icon": "https://act-webstatic.mihoyo.com/game_record/zzzv2/material_icon/material_icon_110502.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 300003,
        "cnt": 95,
        "name": "资深调查员记录",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/f0a16ccc3622b6f1206767e98457036c.png",
        "rarity": "A",
        "not_opened": false
      },
      {
        "id": 301003,
        "cnt": 75,
        "name": "音擎能源模块",
        "icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/dfa35bafaa82d715ffc0d18dace01b16.png",
        "rarity": "A",
        "not_opened": false
      }
    ],
    "coin_icon": "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u7f11d/c46b44f074463f21c25a29b09f136abe.png"
  }
}
```

### 游戏账号详情

- API：https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/index?server=prod_gf_cn&role_id=37716744
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/index?server=prod_gf_cn&role_id=37716744 HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rpc-language: zh-cn
x-rum-tracestate: app_id=484533,origin=rum
Referer: https://act.mihoyo.com/
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
x-rpc-platform: 1
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; acw_tc=2f6fc15617746839162274219e008dd30eed2979fec861bf3f7b0d8124ca1a; aliyungf_tc=725be023e4ebc66dce97483299fed19020d534458c2af4c595121977ef034e1a; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; mi18nLang=zh-cn; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
x-rpc-geetest_ext: {"viewUid":"182692936","server":"prod_gf_cn","gameId":8,"page":"v2.7.1_#/zzz","isHost":1,"viewSource":3,"actionSource":127}
x-rpc-lang: zh-cn
x-rpc-page: v2.7.1_#/zzz
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-lrsag:
Accept: application/json, text/plain, */*
traceparent: 00-62c0ebfde08beeae8d43ec0d0b175355-dc8e422f57791845-01
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-62c0ebfde08beeae8d43ec0d0b175355-dc8e422f57791845-01
```

### 实时便签

- API：https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/note?server=prod_gf_cn&role_id=37716744
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/note?server=prod_gf_cn&role_id=37716744 HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rpc-language: zh-cn
x-rum-tracestate: app_id=484533,origin=rum
Referer: https://act.mihoyo.com/
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
x-rpc-platform: 1
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; acw_tc=2f6fc15617746839162274219e008dd30eed2979fec861bf3f7b0d8124ca1a; aliyungf_tc=725be023e4ebc66dce97483299fed19020d534458c2af4c595121977ef034e1a; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
x-rpc-geetest_ext: {"viewUid":"182692936","server":"prod_gf_cn","gameId":8,"page":"v2.7.1_#/zzz/daily-note","isHost":1,"viewSource":3,"actionSource":127}
x-rpc-lang: zh-cn
x-rpc-page: v2.7.1_#/zzz/daily-note
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-lrsag:
Accept: application/json, text/plain, */*
traceparent: 00-3153d420cc6f5bdd0204d88c83f3a10b-f11a172f7d4e32a6-01
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-3153d420cc6f5bdd0204d88c83f3a10b-f11a172f7d4e32a6-01
```

### 角色列表

- API：https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/avatar/basic?server=prod_gf_cn&role_id=37716744
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/avatar/basic?server=prod_gf_cn&role_id=37716744 HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rpc-language: zh-cn
x-rum-tracestate: app_id=484533,origin=rum
Referer: https://act.mihoyo.com/
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
x-rpc-platform: 1
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; acw_tc=2f6fc15617746839162274219e008dd30eed2979fec861bf3f7b0d8124ca1a; aliyungf_tc=725be023e4ebc66dce97483299fed19020d534458c2af4c595121977ef034e1a; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
x-rpc-geetest_ext: {"viewUid":"182692936","server":"prod_gf_cn","gameId":8,"page":"v2.7.1_#/zzz/roles/1171/detail","isHost":1,"viewSource":3,"actionSource":127}
x-rpc-lang: zh-cn
x-rpc-page: v2.7.1_#/zzz/roles/1171/detail
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-lrsag:
Accept: application/json, text/plain, */*
traceparent: 00-cbd54f945e792f6dd22ca2eea30bfee2-265518593e17e1a5-01
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-cbd54f945e792f6dd22ca2eea30bfee2-265518593e17e1a5-01
```

### 单个角色详情

- API：https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/avatar/info?id_list[]=1171&need_wiki=true&server=prod_gf_cn&role_id=37716744
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/avatar/info?id_list[]=1171&need_wiki=true&server=prod_gf_cn&role_id=37716744 HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rpc-language: zh-cn
x-rum-tracestate: app_id=484533,origin=rum
Referer: https://act.mihoyo.com/
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
x-rpc-platform: 1
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; acw_tc=2f6fc15617746839162274219e008dd30eed2979fec861bf3f7b0d8124ca1a; aliyungf_tc=725be023e4ebc66dce97483299fed19020d534458c2af4c595121977ef034e1a; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
x-rpc-geetest_ext: {"viewUid":"182692936","server":"prod_gf_cn","gameId":8,"page":"v2.7.1_#/zzz/roles/1171/detail","isHost":1,"viewSource":3,"actionSource":127}
x-rpc-lang: zh-cn
x-rpc-page: v2.7.1_#/zzz/roles/1171/detail
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-lrsag:
Accept: application/json, text/plain, */*
traceparent: 00-97a2861eead18f233b09a6b7d3174dff-9c8cc97e934bc712-01
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-97a2861eead18f233b09a6b7d3174dff-9c8cc97e934bc712-01
```

### 本月收入：

- API： https://api-takumi.mihoyo.com/event/nap_ledger/month_info?uid=37716744&region=prod_gf_cn&month=
- 请求方式：GET
  note：如果需要指定的月份，那么就将month改成指定的年月，比如 month=202602
- 请求头示例参数：

```text
GET /event/nap_ledger/month_info?uid=37716744&region=prod_gf_cn&month= HTTP/1.1
Host: api-takumi.mihoyo.com
x-rpc-language: zh-cn
x-rum-tracestate: app_id=484533,origin=rum
Referer: https://act.mihoyo.com/
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
x-rpc-platform: 1
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; aliyungf_tc=2f5d547d24066b322b1fe3e6f0ff29be05d8b7dbc68b8804c39d3e6b6594f4df; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
x-rpc-geetest_ext: {"viewUid":"182692936","server":"prod_gf_cn","gameId":8,"page":"v2.7.1_#/zzz/notebook","isHost":1,"viewSource":3,"actionSource":127}
x-rpc-lang: zh-cn
x-rpc-page: v2.7.1_#/zzz/notebook
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-lrsag:
Accept: application/json, text/plain, */*
traceparent: 00-62c326c43795c3ad883f4d8bfbabeea7-8595d85be5e658d4-01
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-62c326c43795c3ad883f4d8bfbabeea7-8595d85be5e658d4-01
```

### 邦布列表：

- API：https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/buddy/info?role_id=37716744&server=prod_gf_cn
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/buddy/info?role_id=37716744&server=prod_gf_cn HTTP/1.1
Host: api-takumi-record.mihoyo.com
x-rpc-language: zh-cn
x-rum-tracestate: app_id=484533,origin=rum
Referer: https://act.mihoyo.com/
User-Agent: Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2
x-rpc-platform: 1
Cookie: account_id=182692936; account_id_v2=182692936; account_mid_v2=0otk3b2k90_mhy; cookie_token=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; cookie_token_v2=v2_g5nZl9J62-4Rh4Nn2M5GxpuzoOMdt7t7FvwqMDaY1_EfKHAmORkiBPoC_FitORhhPTbBgRSJmFNmxf8P40qN-kvZzh8QPNDKyQbo9g3D6qGyblLd8aBrWhCMLftYSIi6PbwLbi6hddxpnwc-IQ==.CAE=; login_ticket=; ltmid_v2=0otk3b2k90_mhy; ltoken=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltoken_v2=v2_hlh4eoawLf_J7YGCmHzCKTkAoloywUpEwJByqX6Wdk1hCYfxZIzByD0vO55zjXLRpl8xzhlUZ6pdUBJoIiLCNpG6H9zbdB8qSgzNFOMvBsPJ_OsfBWJwDC_lieGvgyN9q8R_Cf4DdHa_9nbhxQ==.CAE=; ltuid=182692936; ltuid_v2=182692936; _MHYUUID=56f0b7b6-a354-4f11-876d-f30d67b0e63f; mi18nLang=zh-cn; acw_tc=2f6fc15617746839162274219e008dd30eed2979fec861bf3f7b0d8124ca1a; aliyungf_tc=725be023e4ebc66dce97483299fed19020d534458c2af4c595121977ef034e1a; _ga=GA1.2.1391720589.1774675650; _gid=GA1.2.1979297185.1774675650; DEVICEFP=38d81709a10bf; DEVICEFP_SEED_ID=cd6d60a67eea9dab; DEVICEFP_SEED_TIME=1774675902405; _ga_K2F0P1NR6Z=GS2.1.s1774683415$o1$g0$t1774683415$j60$l0$h0
x-rpc-geetest_ext: {"viewUid":"182692936","server":"prod_gf_cn","gameId":8,"page":"v2.7.1_#/zzz/bangboo/all","isHost":1,"viewSource":3,"actionSource":127}
x-rpc-lang: zh-cn
x-rpc-page: v2.7.1_#/zzz/bangboo/all
x-rpc-device_name: %E6%9B%BE%E4%BC%9F%E6%9E%97%E7%9A%84iPad
Origin: https://act.mihoyo.com
baggage: apmplus.app_id=484533,apmplus.origin=rum,apmplus.client_domain=https://apmplus.volces.com
Connection: keep-alive
x-rpc-device_fp: 38d815eefa162
x-rpc-app_version: 2.102.0
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-lrsag:
Accept: application/json, text/plain, */*
traceparent: 00-971e6a133c9a3f523bfa1d85d333f47a-1deffa49144df886-01
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
x-rum-traceparent: 00-971e6a133c9a3f523bfa1d85d333f47a-1deffa49144df886-01
```

### Widget API

- API: https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/widget
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/widget HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1776574985,113184,1dbe8021deda1aa4f523d5224124c495
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-sys_version: 15.7.1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_EGONIbcJnb696ZtwCMSlOYGLKHqKiU635XFOdsy2IxK6wT0pveSmktugUloxEt7MoJRNlZNm8I0GKYNqSNCpYW5zx7QNRIFR7D3o5SEppSewtLIzE5TDS0OZX7AxlwauV0idbcmp30eEkDqf9Q==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-device_model: iPad14,1
```

- Response

```text
HTTP/1.1 200 OK
Date: Sun, 19 Apr 2026 05:03:05 GMT
Content-Type: application/json
Content-Length: 1405
Connection: keep-alive
Set-Cookie: aliyungf_tc=e7e1c5c7b9b420fe0181ac64fd50fc09ad3a9a14dafe079e8b9927dc75dfe1cd; Path=/; HttpOnly
Set-Cookie: acw_tc=2f6fc15617765749853037464e0096f71ff8eea8189b08ff3088e387e95969;path=/;HttpOnly;Max-Age=1800
Cache-Control: no-cache
Content-Encoding: gzip
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 1b8c1334946d8cbb:1b8c1334946d8cbb:0:1
Strict-Transport-Security: max-age=31536000

{"retcode":0,"message":"OK","data":{"energy":{"progress":{"max":240,"current":39},"restore":72304,"day_type":2,"hour":9,"minute":8},"vitality":{"max":400,"current":400},"vhs_sale":{"sale_state":"SaleStateDoing"},"card_sign":"CardSignDone","bounty_commission":{"num":0,"total":8000,"refresh_time":53815,"unlock":true},"survey_points":null,"vitality_refresh":53815,"abyss_refresh":53815,"s2_bounty_commission":{"num":0,"total":8000,"refresh_time":53815,"unlock":true},"has_signed":true,"sign_url":"https://act.mihoyo.com/bbs/event/signin/zzz/e202406242138391.html?act_id=e202406242138391\u0026mhy_auth_required=true\u0026mhy_presentation_style=fullscreen\u0026utm_source=h5\u0026utm_medium=zzz\u0026utm_campaign=zj","weekly_task":{"refresh_time":53815,"cur_point":1700,"max_point":2100,"unlock":true},"is_switch_new":true,"note_list":[{"name":"占卜/刮刮卡","name_color":"A6FFFFFF","value":"已完成","value_color":"E5FFFFFF","value_highlight":false},{"name":"录像店经营","name_color":"A6FFFFFF","value":"正在营业","value_color":"E5FFFFFF","value_highlight":false},{"name":"悬赏委托","name_color":"A6FFFFFF","value":"0/8000","value_color":"FFDE00","value_highlight":true},{"name":"丽都周纪积分","name_color":"A6FFFFFF","value":"1700/2100","value_color":"FFDE00","value_highlight":true}],"home_url":"https://act.mihoyo.com/app/mihoyo-zzz-game-record/m.html?mhy_presentation_style=fullscreen","note_url":"https://act.mihoyo.com/app/mihoyo-zzz-game-record/m.html?mhy_presentation_style=fullscreen","cafe_state":"CafeStateDone","activity_list":[{"activity_id":5000136,"state":"STATE_IN_PROGRESS","name":"灾潮特遣分队","monochrome_cnt":300,"monochrome_got_cnt":0,"left_start_ts":0,"left_end_ts":53814,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"},{"activity_id":5000135,"state":"STATE_IN_PROGRESS","name":"老朋友，新委托！","monochrome_cnt":300,"monochrome_got_cnt":180,"left_start_ts":0,"left_end_ts":1349814,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"},{"activity_id":5000134,"state":"STATE_IN_PROGRESS","name":"滚烫寻鲜记","monochrome_cnt":1100,"monochrome_got_cnt":0,"left_start_ts":0,"left_end_ts":1349814,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"},{"activity_id":5000140,"state":"STATE_NOT_START","name":"冒险影像定格帧","monochrome_cnt":300,"monochrome_got_cnt":0,"left_start_ts":248215,"left_end_ts":1349814,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"}],"activity_calendar_url":"https://act.mihoyo.com/app/mihoyo-zzz-game-record/m.html?mhy_presentation_style=fullscreen","hoyo_link_cn":{"HOYO_LINK_TYPE_APP_LINK":"https://oig.mihoyo.com/zenless/?default_url=https%3A%2F%2Foig.mihoyo.com%2Fzenlesscloud%2F%3Fdefault_url%3Dhttps%253A%252F%252Fzzz.mihoyo.com%252Fcloud-feat%252F%253Futm_source%253Dmedia%2526utm_medium%253Dmys%2526utm_campaign%253Dwidgets%252F%2523%252F\u0026source=1\u0026utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets","HOYO_LINK_TYPE_UNIVERSAL_LINK":"https://oig.mihoyo.com/zenless/?default_url=https%3A%2F%2Foig.mihoyo.com%2Fzenlesscloud%2F%3Fdefault_url%3Dhttps%253A%252F%252Fzzz.mihoyo.com%252Fcloud-feat%252F%253Futm_source%253Dmedia%2526utm_medium%253Dmys%2526utm_campaign%253Dwidgets%252F%2523%252F\u0026source=1\u0026utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets","HOYO_LINK_TYPE_DEEPLINK":"zenless://?utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets","HOYO_LINK_TYPE_DEEPLINK_CLOUD":"zenlesscloud://?utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets"},"weekly_task_icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/a5ab444b246d59efe268d91097c74e15_6233780551580630357.png","s2_bounty_commission_icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/f53b7374715909a04d55d54154dc3222_5589071752889643439.png","community_circle_url":"mihoyobbs://homeForum?game_id=8"}}
```

### Widget Version WV_V2

- API: https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/widget?version=WV_V2
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/widget?version=WV_V2 HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1776574984,113184,0c2c617065ae987053ba88cfc3f69f82
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-device_model: iPad14,1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_EGONIbcJnb696ZtwCMSlOYGLKHqKiU635XFOdsy2IxK6wT0pveSmktugUloxEt7MoJRNlZNm8I0GKYNqSNCpYW5zx7QNRIFR7D3o5SEppSewtLIzE5TDS0OZX7AxlwauV0idbcmp30eEkDqf9Q==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-sys_version: 15.7.1
```

- Response

```text
HTTP/1.1 200 OK
Date: Sun, 19 Apr 2026 05:03:04 GMT
Content-Type: application/json
Content-Length: 1405
Connection: keep-alive
Set-Cookie: aliyungf_tc=81cb4e937f06946d6187d8f41fdbb468e5341fa36f21042e6b35a90394cc2dbf; Path=/; HttpOnly
Set-Cookie: acw_tc=2f6fc13d17765749848503050e009fbeebfc46ae847ecccfe83bdb4817213c;path=/;HttpOnly;Max-Age=1800
Cache-Control: no-cache
Content-Encoding: gzip
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 10f80dad78533580:10f80dad78533580:0:1
Strict-Transport-Security: max-age=31536000

{"retcode":0,"message":"OK","data":{"energy":{"progress":{"max":240,"current":39},"restore":72305,"day_type":2,"hour":9,"minute":8},"vitality":{"max":400,"current":400},"vhs_sale":{"sale_state":"SaleStateDoing"},"card_sign":"CardSignDone","bounty_commission":{"num":0,"total":8000,"refresh_time":53816,"unlock":true},"survey_points":null,"vitality_refresh":53816,"abyss_refresh":53816,"s2_bounty_commission":{"num":0,"total":8000,"refresh_time":53816,"unlock":true},"has_signed":true,"sign_url":"https://act.mihoyo.com/bbs/event/signin/zzz/e202406242138391.html?act_id=e202406242138391\u0026mhy_auth_required=true\u0026mhy_presentation_style=fullscreen\u0026utm_source=h5\u0026utm_medium=zzz\u0026utm_campaign=zj","weekly_task":{"refresh_time":53816,"cur_point":1700,"max_point":2100,"unlock":true},"is_switch_new":true,"note_list":[{"name":"占卜/刮刮卡","name_color":"A6FFFFFF","value":"已完成","value_color":"E5FFFFFF","value_highlight":false},{"name":"录像店经营","name_color":"A6FFFFFF","value":"正在营业","value_color":"E5FFFFFF","value_highlight":false},{"name":"悬赏委托","name_color":"A6FFFFFF","value":"0/8000","value_color":"FFDE00","value_highlight":true},{"name":"丽都周纪积分","name_color":"A6FFFFFF","value":"1700/2100","value_color":"FFDE00","value_highlight":true}],"home_url":"https://act.mihoyo.com/app/mihoyo-zzz-game-record/m.html?mhy_presentation_style=fullscreen","note_url":"https://act.mihoyo.com/app/mihoyo-zzz-game-record/m.html?mhy_presentation_style=fullscreen","cafe_state":"CafeStateDone","activity_list":[{"activity_id":5000136,"state":"STATE_IN_PROGRESS","name":"灾潮特遣分队","monochrome_cnt":300,"monochrome_got_cnt":0,"left_start_ts":0,"left_end_ts":53815,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"},{"activity_id":5000135,"state":"STATE_IN_PROGRESS","name":"老朋友，新委托！","monochrome_cnt":300,"monochrome_got_cnt":180,"left_start_ts":0,"left_end_ts":1349815,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"},{"activity_id":5000134,"state":"STATE_IN_PROGRESS","name":"滚烫寻鲜记","monochrome_cnt":1100,"monochrome_got_cnt":0,"left_start_ts":0,"left_end_ts":1349815,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"},{"activity_id":5000140,"state":"STATE_NOT_START","name":"冒险影像定格帧","monochrome_cnt":300,"monochrome_got_cnt":0,"left_start_ts":248216,"left_end_ts":1349815,"icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/065a90405fd05d4ecbd78fd5582d9541_4815400016808490515.png"}],"activity_calendar_url":"https://act.mihoyo.com/app/mihoyo-zzz-game-record/m.html?mhy_presentation_style=fullscreen","hoyo_link_cn":{"HOYO_LINK_TYPE_APP_LINK":"https://oig.mihoyo.com/zenless/?default_url=https%3A%2F%2Foig.mihoyo.com%2Fzenlesscloud%2F%3Fdefault_url%3Dhttps%253A%252F%252Fzzz.mihoyo.com%252Fcloud-feat%252F%253Futm_source%253Dmedia%2526utm_medium%253Dmys%2526utm_campaign%253Dwidgets%252F%2523%252F\u0026source=1\u0026utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets","HOYO_LINK_TYPE_UNIVERSAL_LINK":"https://oig.mihoyo.com/zenless/?default_url=https%3A%2F%2Foig.mihoyo.com%2Fzenlesscloud%2F%3Fdefault_url%3Dhttps%253A%252F%252Fzzz.mihoyo.com%252Fcloud-feat%252F%253Futm_source%253Dmedia%2526utm_medium%253Dmys%2526utm_campaign%253Dwidgets%252F%2523%252F\u0026source=1\u0026utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets","HOYO_LINK_TYPE_DEEPLINK":"zenless://?utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets","HOYO_LINK_TYPE_DEEPLINK_CLOUD":"zenlesscloud://?utm_source=media\u0026utm_medium=mys\u0026utm_campaign=widgets"},"weekly_task_icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/a5ab444b246d59efe268d91097c74e15_6233780551580630357.png","s2_bounty_commission_icon":"https://fastcdn.mihoyo.com/static-resource-v2/2026/01/09/f53b7374715909a04d55d54154dc3222_5589071752889643439.png","community_circle_url":"mihoyobbs://homeForum?game_id=8"}}
```

### Widget Avatar Background API

- API: https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/get_widget_avatar_background
- 请求方式：GET
- 请求头示例参数：

```text
GET /event/game_record_zzz/api/zzz/get_widget_avatar_background HTTP/1.1
Host: api-takumi-record.mihoyo.com
DS: 1776574984,113184,f5233006504c44f99eccc36a005b6ddf
Accept: */*
x-rpc-device_fp:
x-rpc-client_type: 1
x-rpc-device_id: 4DC5ED80-3B76-4E65-9DB1-AB5B41FDDF9A
x-rpc-channel: appstore
Accept-Language: zh-CN,zh-Hans;q=0.9
Accept-Encoding: gzip, deflate, br
x-rpc-device_model: iPad14,1
Referer: https://app.mihoyo.com
x-rpc-device_name:
x-rpc-app_version: 2.104.0
User-Agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
Connection: keep-alive
Cookie: stuid=182692936;stoken=v2_EGONIbcJnb696ZtwCMSlOYGLKHqKiU635XFOdsy2IxK6wT0pveSmktugUloxEt7MoJRNlZNm8I0GKYNqSNCpYW5zx7QNRIFR7D3o5SEppSewtLIzE5TDS0OZX7AxlwauV0idbcmp30eEkDqf9Q==.CAE=;mid=0otk3b2k90_mhy;
x-rpc-sys_version: 15.7.1
```

- Response

```text
HTTP/1.1 200 OK
Date: Sun, 19 Apr 2026 05:03:05 GMT
Content-Type: application/json
Transfer-Encoding: chunked
Connection: keep-alive
Set-Cookie: aliyungf_tc=891132dbc6ac3854b68832b2a2c04ac1e8a77c9b43c8dfe3cf2861b10feab4e4; Path=/; HttpOnly
Set-Cookie: acw_tc=781bad5517765749850504850e00898ef86c17ebfc9fbe283d9a33fbfeb670;path=/;HttpOnly;Max-Age=1800
Cache-Control: no-cache
Content-Encoding: gzip
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 699550936336251b:699550936336251b:0:1
Strict-Transport-Security: max-age=31536000

{"retcode":0,"message":"OK","data":{"avatar_skin_list":[],"element_type_list":[{"id":200,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/00da579567e6a794ffad0847a4225872_4384513503365390623.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/f50c5e7c4fbcdd35af6d7f4e1cfde205_4580345807606343589.png"},{"id":201,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/b6122276899db0cc9db18e6e954ac33f_1233311727252754362.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/abd2e984742f3563c52e52f01ac1b8af_3699498285386666135.png"},{"id":202,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/d8a3018d5525a4298ca95e53f9e47a39_6824026752176190867.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/ccd093f8040b5a87811d587450345cde_2696529776057432609.png"},{"id":203,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/4eb47d91db1f1d1e813b0c23a5c68b73_6553451619642714210.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/48672a30a8068e128f76c4c6b1ba033a_9047740035191912471.png"},{"id":205,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/e91d43250e521cc078c8f1e0461f736b_908443609843872226.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/0beb498d28f39c0e4f030bcc1fe86b35_2485628652556462471.png"}],"avatar_profession_list":[{"id":1,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/4336ab0e523def9a5c513e63473132e9_3713275612417536129.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/e1713df63d13c7feab25489cd038b388_6715478898532017819.png"},{"id":2,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/78c2f7e089f6e111a1e12192c173cd59_1858520671267958840.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/c932587ef41205d0c0d036319061910f_7751137083621868091.png"},{"id":3,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/5d8cb08b702538a657f0edad36281d51_3747719242028954426.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/d62d2dd3af316acf5c80d88bb2e1a83e_388294159870062915.png"},{"id":4,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/f741760c3df02c4d2580032089bed453_8138445942569754481.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/759d5b736835cc1fae2ac33236a4a016_1375281875877207322.png"},{"id":5,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/48fa8fede784cae32fc0998c5e1c914a_3111397452986251680.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/5c0620ad0d65e7910c6b48afc31fa31d_7143815670645568898.png"},{"id":6,"icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/4f44f1f48dbdc06c54976bb59deefb0c_3945898950350237007.png","select_icon_url":"https://fastcdn.mihoyo.com/mi18n/nap_cn/m20240410hy38foxb7k/upload/fd2cd76bfe38515c115c4083f56fa0a7_3609039556069612784.png"}],"avatar_skin_list_v2":[{"avatar_id":1011,"skin_name":"安比·街头迅影","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1011.png","element_type":203,"avatar_profession":2,"skin_id":0,"color":"#c8e16c"},{"avatar_id":1021,"skin_name":"猫又·猫的报恩","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1021.png","element_type":200,"avatar_profession":1,"skin_id":0,"color":"#a0351c"},{"avatar_id":1031,"skin_name":"妮可·一点点俏皮","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1031.png","element_type":205,"avatar_profession":4,"skin_id":0,"color":"#e6adaa"},{"avatar_id":1031,"skin_name":"妮可·狡黠甜心","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1031_3110311.png","element_type":205,"avatar_profession":4,"skin_id":3110311,"color":"#e6adaa"},{"avatar_id":1041,"skin_name":"「11号」·精锐士兵","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1041.png","element_type":201,"avatar_profession":1,"skin_id":0,"color":"#febb2e"},{"avatar_id":1051,"skin_name":"伊德海莉·遐思漫录","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1051.png","element_type":202,"avatar_profession":6,"skin_id":0,"color":"#9236be"},{"avatar_id":1061,"skin_name":"可琳·抹茶泡芙","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1061.png","element_type":200,"avatar_profession":1,"skin_id":0,"color":"#c8d7bd"},{"avatar_id":1071,"skin_name":"凯撒·火浴焰行","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1071.png","element_type":200,"avatar_profession":5,"skin_id":0,"color":"#da8837"},{"avatar_id":1081,"skin_name":"比利·闪耀星徽套装","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1081.png","element_type":200,"avatar_profession":1,"skin_id":0,"color":"#af3e3a"},{"avatar_id":1091,"skin_name":"星见雅·烈露濯霜","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1091.png","element_type":202,"avatar_profession":3,"skin_id":0,"color":"#05777a"},{"avatar_id":1101,"skin_name":"珂蕾妲·赤子烈锤","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1101.png","element_type":201,"avatar_profession":2,"skin_id":0,"color":"#de643d"},{"avatar_id":1111,"skin_name":"安东·撼地炽轴","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1111.png","element_type":203,"avatar_profession":1,"skin_id":0,"color":"#ddc374"},{"avatar_id":1121,"skin_name":"本·兽王毛茸茸","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1121.png","element_type":201,"avatar_profession":5,"skin_id":0,"color":"#a68d73"},{"avatar_id":1131,"skin_name":"苍角·青蓝冰舞","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1131.png","element_type":202,"avatar_profession":4,"skin_id":0,"color":"#28bdcc"},{"avatar_id":1141,"skin_name":"莱卡恩·苍月夜巡","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1141.png","element_type":202,"avatar_profession":2,"skin_id":0,"color":"#d0d3e0"},{"avatar_id":1151,"skin_name":"露西·铁腕淑女","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1151.png","element_type":201,"avatar_profession":4,"skin_id":0,"color":"#e8cda2"},{"avatar_id":1161,"skin_name":"莱特·不熄烬炎","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1161.png","element_type":201,"avatar_profession":2,"skin_id":0,"color":"#be3b2b"},{"avatar_id":1171,"skin_name":"柏妮思·纵燃欢宴","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1171.png","element_type":201,"avatar_profession":3,"skin_id":0,"color":"#da8837"},{"avatar_id":1181,"skin_name":"格莉丝·钢铁的女巫","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1181.png","element_type":203,"avatar_profession":3,"skin_id":0,"color":"#b75339"},{"avatar_id":1191,"skin_name":"艾莲·剪刀手艾鲨鲨","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1191.png","element_type":202,"avatar_profession":1,"skin_id":0,"color":"#c9becc"},{"avatar_id":1191,"skin_name":"艾莲·从周一到周五","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1191_3111911.png","element_type":202,"avatar_profession":1,"skin_id":3111911,"color":"#c9becc"},{"avatar_id":1201,"skin_name":"浅羽悠真·落弦飞羽","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1201.png","element_type":203,"avatar_profession":1,"skin_id":0,"color":"#e1c600"},{"avatar_id":1211,"skin_name":"丽娜·完美女仆长","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1211.png","element_type":203,"avatar_profession":4,"skin_id":0,"color":"#c4c1b1"},{"avatar_id":1221,"skin_name":"月城柳·月影流华","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1221.png","element_type":203,"avatar_profession":3,"skin_id":0,"color":"#d55b68"},{"avatar_id":1241,"skin_name":"朱鸢·镇暴者","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1241.png","element_type":205,"avatar_profession":1,"skin_id":0,"color":"#4e7ebd"},{"avatar_id":1251,"skin_name":"青衣·清平乐","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1251.png","element_type":203,"avatar_profession":2,"skin_id":0,"color":"#28c79d"},{"avatar_id":1261,"skin_name":"简·夜隐阑珊","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1261.png","element_type":200,"avatar_profession":3,"skin_id":0,"color":"#86d4e8"},{"avatar_id":1261,"skin_name":"简·漪光夜曲","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1261_3112611.png","element_type":200,"avatar_profession":3,"skin_id":3112611,"color":"#86d4e8"},{"avatar_id":1271,"skin_name":"赛斯·不染澄心","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1271.png","element_type":203,"avatar_profession":5,"skin_id":0,"color":"#136dd5"},{"avatar_id":1281,"skin_name":"派派·快与慢","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1281.png","element_type":200,"avatar_profession":3,"skin_id":0,"color":"#e9d892"},{"avatar_id":1291,"skin_name":"雨果·无冕歧命","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1291.png","element_type":202,"avatar_profession":1,"skin_id":0,"color":"#EECC7B"},{"avatar_id":1301,"skin_name":"奥菲丝\u0026 「鬼火」·冥河两渡","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1301.png","element_type":201,"avatar_profession":1,"skin_id":0,"color":"#fd7e17"},{"avatar_id":1311,"skin_name":"耀嘉音·绯红摇滚","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1311.png","element_type":205,"avatar_profession":4,"skin_id":0,"color":"#D12D4E"},{"avatar_id":1311,"skin_name":"耀嘉音·水晶灯下","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1311_3113111.png","element_type":205,"avatar_profession":4,"skin_id":3113111,"color":"#D12D4E"},{"avatar_id":1321,"skin_name":"伊芙琳·飞蛾逐光","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1321.png","element_type":201,"avatar_profession":1,"skin_id":0,"color":"#9D5EF1"},{"avatar_id":1331,"skin_name":"薇薇安·堇色蹁跹","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1331.png","element_type":205,"avatar_profession":3,"skin_id":0,"color":"#C77DFB"},{"avatar_id":1331,"skin_name":"薇薇安·鸢花池畔","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1331_3113311.png","element_type":205,"avatar_profession":3,"skin_id":3113311,"color":"#C77DFB"},{"avatar_id":1341,"skin_name":"照·绒耳寒枝","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1341.png","element_type":202,"avatar_profession":5,"skin_id":0,"color":"#e8b6ae"},{"avatar_id":1351,"skin_name":"波可娜·倦尾栖痕","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1351.png","element_type":200,"avatar_profession":2,"skin_id":0,"color":"#EB721B"},{"avatar_id":1361,"skin_name":"「扳机」·幽目启明","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1361.png","element_type":203,"avatar_profession":2,"skin_id":0,"color":"#FFD632"},{"avatar_id":1371,"skin_name":"仪玄·观云同岿","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1371.png","element_type":205,"avatar_profession":6,"skin_id":0,"color":"#b7986f"},{"avatar_id":1371,"skin_name":"仪玄·墨形影踪","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1371_3113711.png","element_type":205,"avatar_profession":6,"skin_id":3113711,"color":"#b7986f"},{"avatar_id":1381,"skin_name":"零号·安比·银心锡兵","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1381.png","element_type":203,"avatar_profession":1,"skin_id":0,"color":"#F7940A"},{"avatar_id":1391,"skin_name":"橘福福·山中萌虎","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1391.png","element_type":201,"avatar_profession":2,"skin_id":0,"color":"#e29737"},{"avatar_id":1401,"skin_name":"爱丽丝·圣星裁仪","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1401.png","element_type":200,"avatar_profession":3,"skin_id":0,"color":"#debe8d"},{"avatar_id":1401,"skin_name":"爱丽丝·百里香之海","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1401_3114011.png","element_type":200,"avatar_profession":3,"skin_id":3114011,"color":"#debe8d"},{"avatar_id":1411,"skin_name":"柚叶·伞下梦貉","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1411.png","element_type":200,"avatar_profession":4,"skin_id":0,"color":"#b92734"},{"avatar_id":1411,"skin_name":"柚叶·晴空化狸","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1411_3114111.png","element_type":200,"avatar_profession":4,"skin_id":3114111,"color":"#b92734"},{"avatar_id":1421,"skin_name":"潘引壶·食引百味","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1421.png","element_type":200,"avatar_profession":5,"skin_id":0,"color":"#c84342"},{"avatar_id":1421,"skin_name":"潘引壶·馔玉烹金","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1421_3114211.png","element_type":200,"avatar_profession":5,"skin_id":3114211,"color":"#c84342"},{"avatar_id":1431,"skin_name":"叶瞬光·流云照影","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1431.png","element_type":200,"avatar_profession":1,"skin_id":0,"color":"#de493e"},{"avatar_id":1431,"skin_name":"叶瞬光·暖霞拾光","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1431_3114311.png","element_type":200,"avatar_profession":1,"skin_id":3114311,"color":"#de493e"},{"avatar_id":1441,"skin_name":"狛野真斗·赤心荒魂","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1441.png","element_type":201,"avatar_profession":6,"skin_id":0,"color":"#b83a37"},{"avatar_id":1441,"skin_name":"狛野真斗·白心旧影","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1441_3114411.png","element_type":201,"avatar_profession":6,"skin_id":3114411,"color":"#b83a37"},{"avatar_id":1451,"skin_name":"卢西娅·颂夜梦呓","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1451.png","element_type":205,"avatar_profession":4,"skin_id":0,"color":"#25999d"},{"avatar_id":1461,"skin_name":"「席德」·繁花","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1461.png","element_type":203,"avatar_profession":1,"skin_id":0,"color":"#aed5dd"},{"avatar_id":1471,"skin_name":"般岳·灼业石心","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1471.png","element_type":201,"avatar_profession":6,"skin_id":0,"color":"#e8a03a"},{"avatar_id":1481,"skin_name":"琉音·铃语判词","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1481.png","element_type":200,"avatar_profession":2,"skin_id":0,"color":"#1db0af"},{"avatar_id":1491,"skin_name":"千夏·妄念环响","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1491.png","element_type":200,"avatar_profession":4,"skin_id":0,"color":"#daef94"},{"avatar_id":1491,"skin_name":"千夏·午后茶歇","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1491_3114911.png","element_type":200,"avatar_profession":4,"skin_id":3114911,"color":"#daef94"},{"avatar_id":1501,"skin_name":"爱芮·元气偶像","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1501.png","element_type":205,"avatar_profession":3,"skin_id":0,"color":"#8deeb7"},{"avatar_id":1501,"skin_name":"爱芮·不协和音","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1501_3115011.png","element_type":205,"avatar_profession":3,"skin_id":3115011,"color":"#8deeb7"},{"avatar_id":1511,"skin_name":"南宫羽·绮梦领舞","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1511.png","element_type":205,"avatar_profession":2,"skin_id":0,"color":"#9c77f2"},{"avatar_id":1511,"skin_name":"南宫羽·狂想缪斯","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1511_3115111.png","element_type":205,"avatar_profession":2,"skin_id":3115111,"color":"#9c77f2"},{"avatar_id":1521,"skin_name":"希希芙·蛇鼠游戏","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_1521.png","element_type":203,"avatar_profession":1,"skin_id":0,"color":"#f04a79"},{"avatar_id":2011,"skin_name":"哲·丽都漫行","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_2011.png","element_type":0,"avatar_profession":0,"skin_id":4120110,"color":"#d2672a"},{"avatar_id":2011,"skin_name":"哲·鹤唳青霄","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_2011_4120111.png","element_type":0,"avatar_profession":0,"skin_id":4120111,"color":"#d2672a"},{"avatar_id":2011,"skin_name":"哲·浪影闲庭","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_2011_4120112.png","element_type":0,"avatar_profession":0,"skin_id":4120112,"color":"#d2672a"},{"avatar_id":2021,"skin_name":"铃·元气店长","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_2021.png","element_type":0,"avatar_profession":0,"skin_id":4120210,"color":"#d2672a"},{"avatar_id":2021,"skin_name":"铃·曦色玲珑","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_2021_4120211.png","element_type":0,"avatar_profession":0,"skin_id":4120211,"color":"#d2672a"},{"avatar_id":2021,"skin_name":"铃·夏日晴空","skin_background_url":"https://act-webstatic.mihoyo.com/game_record/zzzv2/role_teaser_avatar/role_teaser_avatar_2021_4120212.png","element_type":0,"avatar_profession":0,"skin_id":4120212,"color":"#d2672a"}]}}
```

---

## Mock 环境测试 Cookie

Mock 模式下，MockService 从 Cookie 的 `account_id` 字段提取账号标识，路由到对应的 mock 子目录。

### Account 1 — CainLuo（uid: 182692936）

路由目录：`mock/account1/`

```
account_id=182692936; cookie_token=mock; ltoken=mock; ltuid=182692936; stoken=mock;
```

### Account 2 — 摆烂的班主任（uid: 348366494）

路由目录：`mock/account2/`

```
account_id=348366494; cookie_token=mock; ltoken=mock; ltuid=348366494; stoken=mock;
```

> 注意：Mock 模式下 Cookie 的其他字段（`cookie_token`、`ltoken`、`ltuid`）不参与实际验证，只有 `account_id` 用于子目录路由。
