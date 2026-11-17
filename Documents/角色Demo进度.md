# 角色 Demo 开发进度

2026-11-17：阶段一完成。已接入待机、行走和分段跳跃动画，加入逐帧脚底对齐；实现 A/D 移动、W 可变跳高，无二段跳、无离台宽限或提前落地缓冲。

入口 Test.tscn，内嵌 Scenes/Tests/PlayerPlayground.tscn。场地提供平地、墙壁、台阶、可达平台和低顶区域。独立 Player.tscn 可复用，参数见 Resources/Player/default_tuning.tres。

验证：tools/verify-player.ps1 使用新进程、Dummy 音频与 headless 模式，13/13 输入及物理检查通过。测试先在缺少场景时失败（退出码1），实现后通过；覆盖 A/D、朝向、短长跳高度、落地、禁止双跳、墙顶、平台和脚底对齐。运行截图已检查；手感仍需玩家试玩。

待开发：闪避、奔跑、两段普攻、练习靶和打击反馈。下砸按用户决定延期，符箓与油纸伞不在本轮。
