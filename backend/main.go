package main

import (
    "context"
    "log"
    "vps-tracker/config"
    "vps-tracker/handlers"
    "vps-tracker/middleware"
    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
    cfg := config.Load()

    // 连接数据库
    client, err := mongo.Connect(context.Background(), options.Client().ApplyURI(cfg.DBUrl))
    if err != nil {
        log.Fatal(err)
    }
    defer client.Disconnect(context.Background())

    // 初始化处理器
    h := handlers.NewHandler(client.Database("vps-tracker"), cfg)

    // 创建默认管理员
    if err := h.InitAdmin(); err != nil {
        log.Printf("Error creating admin: %v", err)
    }

    // 设置路由
    r := gin.Default()
    r.Use(cors.Default())

    api := r.Group("/api")
    {
        api.POST("/login", h.Login)
        api.POST("/register", h.Register)

        vps := api.Group("/vps")
        {
            vps.GET("", h.ListVPS)
            vps.Use(middleware.Auth(cfg.JWTSecret))
            vps.POST("", h.CreateVPS)
            vps.PUT("/:id", h.UpdateVPS)
            vps.DELETE("/:id", h.DeleteVPS)
        }
    }

    log.Fatal(r.Run(cfg.ListenAddr))
} 