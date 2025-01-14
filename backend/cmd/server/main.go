package main

import (
    "log"
    "github.com/Kpowered/vps-value-tracker/internal/api"
    "github.com/Kpowered/vps-value-tracker/internal/config"
)

func main() {
    // 加载配置
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("Failed to load config: %v", err)
    }

    // 初始化API服务器
    server := api.NewServer(cfg)
    
    // 启动服务器
    if err := server.Run(); err != nil {
        log.Fatalf("Server failed to start: %v", err)
    }
} 