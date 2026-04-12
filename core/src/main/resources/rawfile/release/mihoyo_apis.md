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
    "item_id": "1504",
    "cur_level": 1,
    "target_level": 80
  },
  "skill_list": [
    {
      "item_id": "1504001",
      "cur_level": 1,
      "target_level": 6
    },
    {
      "item_id": "1504002",
      "cur_level": 1,
      "target_level": 10
    },
    {
      "item_id": "1504003",
      "cur_level": 1,
      "target_level": 10
    },
    {
      "item_id": "1504004",
      "cur_level": 1,
      "target_level": 10
    },
    {
      "item_id": "1504101",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504102",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504103",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504201",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504202",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504203",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504204",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504205",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504206",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504207",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504208",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504209",
      "cur_level": 1,
      "target_level": 1
    },
    {
      "item_id": "1504210",
      "cur_level": 1,
      "target_level": 1
    }
  ],
  "lang": "zh-cn",
  "uid": "102731382",
  "region": "prod_gf_cn"
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
  "avatar_id": 1051,
  "avatar_level": 60,
  "avatar_current_level": 1,
  "avatar_current_promotes": 1,
  "skills": [
    {
      "skill_type": 0,
      "level": 12,
      "init_level": 1
    },
    {
      "skill_type": 1,
      "level": 12,
      "init_level": 1
    },
    {
      "skill_type": 2,
      "level": 12,
      "init_level": 1
    },
    {
      "skill_type": 3,
      "level": 12,
      "init_level": 1
    },
    {
      "skill_type": 5,
      "level": 7,
      "init_level": 1
    },
    {
      "skill_type": 6,
      "level": 12,
      "init_level": 1
    }
  ]
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

---

## Mock 环境测试 Cookie

Mock 模式下，MockService 从 Cookie 的 `account_id` 字段提取账号标识，路由到对应的 mock 子目录。

### Account 1 — CainLuo（uid: 182692936）

路由目录：`mock/account1/`

```
account_id=182692936; cookie_token=mock; ltoken=mock; ltuid=182692936
```

### Account 2 — 摆烂的班主任（uid: 348366494）

路由目录：`mock/account2/`

```
account_id=348366494; cookie_token=mock; ltoken=mock; ltuid=348366494
```

> 注意：Mock 模式下 Cookie 的其他字段（`cookie_token`、`ltoken`、`ltuid`）不参与实际验证，只有 `account_id` 用于子目录路由。
