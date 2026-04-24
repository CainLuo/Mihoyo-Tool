# Request Issues

- API: https://api-takumi-record.mihoyo.com/game_record/app/genshin/aapi/widget/v2
- Request

```text
GET /game_record/app/genshin/aapi/widget/v2 HTTP/1.1
Host: api-takumi-record.mihoyo.com
Accept-Encoding: deflate, gzip, br
accept: application/json, text/plain, */*
cookie: stuid=348366494;stoken=v2_RKTFs-hHl44W6q_DnBqgptgJrtCypaxb2ZKUqOW0grbA1EqXdsydxXeTB46XgYDgExwiTcA3kPOIwBYg18R3lQ7rFkl9D2q5LH_Ij_ZGZHdwjieupvtQ5ZC4Ow49p3hTr6NGHj05fpXMQ9dy0Dk=.CAE=;mid=0tv0t26wei_mhy
ds: 1777011892,134535,7eebdaa7c7c15b738d2bf9fdf9e1ac24
origin: https://app.mihoyo.com
referer: https://app.mihoyo.com
user-agent: WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0
x-requested-with: com.mihoyo.hyperion
x-rpc-app_version: 2.104.0
x-rpc-client_type: 1
x-rpc-device_fp: 38d8179700e69
x-rpc-device_id: 7f73da09-a798-4101-aaf6-8add23ab3819
x-rpc-language: zh-cn
x-rpc-sys_version: 16.3.1
```

- Response

```text
HTTP/1.1 200 OK
Date: Fri, 24 Apr 2026 06:24:52 GMT
Content-Type: application/json
Content-Length: 58
Connection: keep-alive
Set-Cookie: aliyungf_tc=1b06e3178be3d52f28a421b459793570824dae8ad3449b91bc49011161e6915e; Path=/; HttpOnly
Set-Cookie: acw_tc=2f6fc17717770118925454657e009b2eb2ba10677e12337fb7ffd12ca05914;path=/;HttpOnly;Max-Age=1800
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: https://app.mihoyo.com
Access-Control-Expose-Headers: X-Rpc-Aigis, X-Trace-Id
Cache-Control: no-cache
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 54c92d16e5b9ffe0:54c92d16e5b9ffe0:0:1
Strict-Transport-Security: max-age=31536000

{"data":null,"message":"invalid request","retcode":-10001}
```

- API: https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote?role_id=250375401&server=cn_gf01
- Request

```
GET /game_record/app/genshin/api/dailyNote?role_id=250375401&server=cn_gf01 HTTP/1.1
Host: api-takumi-record.mihoyo.com
Accept-Encoding: deflate, gzip, br
accept: application/json, text/plain, */*
cookie: account_id=348366494; cookie_token=TX18n2rt7fGlXz9nJjx64JHMXntEOfKDemITRbCt; ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; ltuid=348366494; stoken=v2_RKTFs-hHl44W6q_DnBqgptgJrtCypaxb2ZKUqOW0grbA1EqXdsydxXeTB46XgYDgExwiTcA3kPOIwBYg18R3lQ7rFkl9D2q5LH_Ij_ZGZHdwjieupvtQ5ZC4Ow49p3hTr6NGHj05fpXMQ9dy0Dk=.CAE=; stuid=348366494; mid=0tv0t26wei_mhy
ds: 1777011891,182868,2e235c895a69a21298c83e9969ccb457
origin: https://webstatic.mihoyo.com
referer: https://webstatic.mihoyo.com/
user-agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.104.0
x-requested-with: com.mihoyo.hyperion
x-rpc-app_version: 2.104.0
x-rpc-client_type: 5
x-rpc-device_fp: 38d8179700e69
x-rpc-device_id: 7f73da09-a798-4101-aaf6-8add23ab3819
x-rpc-language: zh-cn
x-rpc-page: v6.4.2-gr-cn_#/ys
x-rpc-sys_version: 16.3.1
x-rpc-tool_verison: v6.4.2-gr-cn
```

- Response

```tet
HTTP/1.1 200 OK
Date: Fri, 24 Apr 2026 06:24:52 GMT
Content-Type: application/json
Content-Length: 41
Connection: keep-alive
Set-Cookie: aliyungf_tc=65f4cd436142dca845c725ddefb2889b079dd85c274f005c7b4880ba7d49722a; Path=/; HttpOnly
Set-Cookie: acw_tc=2f6fc17717770118922544621e009bcc29527fffb53d6dde3975f3c1f0d51a;path=/;HttpOnly;Max-Age=1800
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: https://webstatic.mihoyo.com
Access-Control-Expose-Headers: X-Rpc-Aigis, X-Trace-Id
Cache-Control: no-cache
Set-Cookie: ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; Path=/; Domain=mihoyo.com; Max-Age=31536000
Set-Cookie: ltuid=348366494; Path=/; Domain=mihoyo.com; Max-Age=31536000
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 27e7f6896d07804f:27e7f6896d07804f:0:1
Strict-Transport-Security: max-age=31536000

{"data":null,"message":"","retcode":1034}
```

## PizzaHelperUnited

- API: https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote?role_id=250375401&server=cn_gf01
- Request

```text
GET /game_record/app/genshin/aapi/widget/v2? HTTP/1.1
Host: api-takumi-record.mihoyo.com
Cookie: stuid=348366494; stoken=v2_CSKbQ-bMFv0j_gUyJjS7sqMa95k02TLx83e1za97MJfkhggyzDI-0Fxh1-jwROozo64TzMByrvTT0EI8YWKvzCD50Obrrw==.CAE=; ltuid=348366494; ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; mid=0tv0t26wei_mhy;
Referer: https://webstatic.mihoyo.com
X-Requested-With: com.mihoyo.hyperion
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.40.1
Cache-Control: no-cache
x-rpc-language: zh-cn
x-rpc-page: 3.1.3_#/rpg
Origin: https://webstatic.mihoyo.com
Sec-Fetch-Dest: empty
Sec-Fetch-Site: same-site
Connection: keep-alive
x-rpc-device_fp: 38d817b971835
x-rpc-app_version: 2.40.1
DS: 1777015257,120029,163c9c35f126418ce1ad048b3a1e53a7
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-client_type: 5
x-rpc-device_id: C9039439-CDEC-468D-8601-C95330EBEE2A
Accept: application/json, text/plain, */*
Accept-Encoding: gzip, deflate, br
Sec-Fetch-Mode: cors
```

- Response

```text
HTTP/1.1 200 OK
Date: Fri, 24 Apr 2026 07:20:57 GMT
Content-Type: application/json
Content-Length: 755
Connection: keep-alive
Set-Cookie: aliyungf_tc=918a211d0f6e5c8b101f8c68d99851277aa52e6934e428fc1fe0d0924e888c15; Path=/; HttpOnly
Set-Cookie: acw_tc=781bad6417770152571388993e0087215306fc337c1dd4bbe40a6f400ce6de;path=/;HttpOnly;Max-Age=1800
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: https://webstatic.mihoyo.com
Access-Control-Expose-Headers: X-Rpc-Aigis, X-Trace-Id
Cache-Control: no-cache
Content-Encoding: gzip
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 3cfeac1eb5ed6182:3cfeac1eb5ed6182:0:1
Strict-Transport-Security: max-age=31536000

{"retcode":0,"message":"OK","data":{"current_resin":82,"max_resin":200,"resin_recovery_time":"56496","finished_task_num":4,"total_task_num":4,"is_extra_task_reward_received":true,"current_expedition_num":5,"max_expedition_num":5,"expeditions":[{"avatar_side_icon":"https://fastcdn.mihoyo.com/static-resource-v2/2023/12/14/a273217a806ee130b0c0f51bc5542483_2404530785826539052.png","status":"Ongoing"},{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/db95c5527a3b0f1a59743180e531be63.png","status":"Ongoing"},{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/2ad457efe47f31a54bd683286fd03144.png","status":"Ongoing"},{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/4e729aba062b54ac30a6351664e19ff1.png","status":"Ongoing"},{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/455ee1e4da29c15282faba8243bccdcc.png","status":"Ongoing"}],"current_home_coin":630,"max_home_coin":2400,"has_signed":true,"sign_url":"https://act.mihoyo.com/bbs/event/signin/hk4e/index.html?act_id=e202311201442471\u0026bbs_auth_required=true\u0026bbs_presentation_style=fullscreen\u0026mhy_presentation_style=fullscreen\u0026utm_source=bbs\u0026utm_medium=ys\u0026utm_campaign=widget","daily_task":null,"home_url":"https://webstatic.mihoyo.com/app/community-game-records/?bbs_presentation_style=fullscreen\u0026mhypresentationstyle=fullscreen\u0026bbs_auth_required=true\u0026gid=2","note_url":"https://webstatic.mihoyo.com/app/community-game-records/?bbs_presentation_style=fullscreen\u0026bbs_auth_required=true#/ys/daily","act_list":[],"avatar_background":"","week_active_progress":{"progress_current":5,"progress_total":5,"period_progress_current":8,"period_progress_total":8,"unlock":true,"progress_current_arr":[1,2,3,4,5],"is_active_period":true,"current_weekday":5}}}
```

- API: https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote?role_id=250375401&server=cn_gf01
- Request

```text
GET /game_record/app/genshin/api/dailyNote?role_id=250375401&server=cn_gf01 HTTP/1.1
Host: api-takumi-record.mihoyo.com
Cookie: stuid=348366494; stoken=v2_CSKbQ-bMFv0j_gUyJjS7sqMa95k02TLx83e1za97MJfkhggyzDI-0Fxh1-jwROozo64TzMByrvTT0EI8YWKvzCD50Obrrw==.CAE=; ltuid=348366494; ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; mid=0tv0t26wei_mhy;
Referer: https://webstatic.mihoyo.com
X-Requested-With: com.mihoyo.hyperion
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.40.1
Cache-Control: no-cache
x-rpc-language: zh-cn
x-rpc-page: 3.1.3_#/rpg
Origin: https://webstatic.mihoyo.com
Sec-Fetch-Dest: empty
Sec-Fetch-Site: same-site
Connection: keep-alive
x-rpc-device_fp: 38d817b971835
x-rpc-app_version: 2.40.1
DS: 1777015256,172532,48b68c3787c2c4751d828ff6f4aca768
Accept-Language: zh-CN,zh-Hans;q=0.9
x-rpc-client_type: 5
x-rpc-device_id: C9039439-CDEC-468D-8601-C95330EBEE2A
Accept: application/json, text/plain, */*
Accept-Encoding: gzip, deflate, br
Sec-Fetch-Mode: cors
```

- Response

```text
HTTP/1.1 200 OK
Date: Fri, 24 Apr 2026 07:20:57 GMT
Content-Type: application/json
Content-Length: 41
Connection: keep-alive
Set-Cookie: aliyungf_tc=a1d7e23734472848fd0598434dab0ffbbf1bacda30507678df6ae276122cf2b5; Path=/; HttpOnly
Set-Cookie: acw_tc=781bad6417770152569808981e00876819ce676d21f0e4f8fd8fc91952956f;path=/;HttpOnly;Max-Age=1800
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: https://webstatic.mihoyo.com
Access-Control-Expose-Headers: X-Rpc-Aigis, X-Trace-Id
Cache-Control: no-cache
Set-Cookie: ltoken=osJWL2YdeJcgRhSW3tRVdaGXrjCDXykMW2LAaXAG; Path=/; Domain=mihoyo.com; Max-Age=31536000
Set-Cookie: ltuid=348366494; Path=/; Domain=mihoyo.com; Max-Age=31536000
Vary: Origin
Vary: Accept-Encoding
X-Powered-By: takumi
X-Trace-Id: 43b67eb426adc6c2:43b67eb426adc6c2:0:1
Strict-Transport-Security: max-age=31536000

{"data":null,"message":"","retcode":1034}
```
