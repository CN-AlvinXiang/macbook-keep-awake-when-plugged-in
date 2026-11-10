# lid-awake-on-ac

**插电合盖不睡眠，拔电合盖正常睡眠**——一键安装的 macOS 小工具。

适合：把 MacBook 当"服务器"用，插着电合上盖子仍想远程操控（SSH、跑任务、下载），
而用电池时又希望它照常休眠省电。

## 为什么需要它

- 系统设置里"接电源时防止自动睡眠"只管**闲置/息屏**，**不管合盖**，合盖仍会睡。
- `sudo pmset -a disablesleep 1` 能让合盖不睡，但这是**全局开关，不区分电源**，
  忘了关会在电池下合盖也不睡，发热又耗电。
- 本工具装一个 root 级 launchd 守护任务，每 10 秒按当前供电状态自动切换：

| 供电状态 | `disablesleep` | 合盖后 |
| --- | --- | --- |
| 接电源 | 1 | 不睡眠 |
| 电池 | 0 | 正常睡眠 |

## 使用

需要管理员权限，运行时会请求 sudo 密码。

```bash
bash lid-awake-on-ac.sh install     # 安装并立即生效
bash lid-awake-on-ac.sh status      # 查看状态（无需 sudo）
bash lid-awake-on-ac.sh uninstall   # 卸载并恢复系统默认
```

`status` 输出示例：

```
供电：Now drawing from 'AC Power'
SleepDisabled：1  （1=合盖不睡，0=正常睡眠）
守护任务：已安装
```

## 会改动什么

- `/usr/local/bin/lid-awake-on-ac-worker.sh`：按供电状态切换开关的小脚本
- `/Library/LaunchDaemons/com.local.lid-awake-on-ac.plist`：每 10 秒触发一次的守护任务
- 系统电源设置里的 `disablesleep`

`uninstall` 会删除以上两个文件并把 `disablesleep` 置 0。

## 注意事项

- 插电合盖时机器持续运行会发热，**别放进包里或盖着被子**。
- 拔电后最多 10 秒才恢复睡眠；这 10 秒内合着盖也不会睡。
- 合盖后若用屏幕共享远程，可能没有画面或分辨率异常；SSH 等命令行方式不受影响。
- 重复执行 `install` 是安全的（会先卸旧再装新）。

## 已验证与未验证

- 已验证（macOS 26 / Apple Silicon）：插电时 `SleepDisabled` 为 1，拔电后变为 0。
- 未验证：合盖后实际保持网络在线的时长、其他 macOS 版本。

## 系统要求

macOS，自带 `pmset` 与 `launchctl`，无其他依赖。
