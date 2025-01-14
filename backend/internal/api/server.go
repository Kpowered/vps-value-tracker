package api

import (
    "github.com/gin-gonic/gin"
    "github.com/Kpowered/vps-value-tracker/internal/config"
    "github.com/Kpowered/vps-value-tracker/internal/db"
    "github.com/Kpowered/vps-value-tracker/internal/middleware"
    "github.com/Kpowered/vps-value-tracker/internal/service"
)

type Server struct {
    cfg     *config.Config
    db      *db.MongoDB
    router  *gin.Engine
    vps     *service.VPSService
    rates   *service.RateService
    auth    *service.AuthService
}

func NewServer(cfg *config.Config) *Server {
    mongodb, err := db.NewMongoDB(cfg)
    if err != nil {
        panic(err)
    }

    if err := mongodb.InitializeCollections(); err != nil {
        panic(err)
    }

    rates := service.NewRateService(cfg)
    vps := service.NewVPSService(mongodb, rates)
    auth := service.NewAuthService(mongodb, cfg)

    server := &Server{
        cfg:    cfg,
        db:     mongodb,
        router: gin.New(),
        vps:    vps,
        rates:  rates,
        auth:   auth,
    }

    server.router.Use(gin.Logger())
    server.router.Use(gin.Recovery())
    server.router.Use(middleware.CORS())
    server.router.Use(middleware.ErrorHandler())

    server.setupRoutes()
    return server
}

func (s *Server) setupRoutes() {
    api := s.router.Group("/api")
    
    // 认证路由
    api.POST("/auth/login", s.handleLogin)
    
    // 公开路由
    api.GET("/vps", s.handleGetAllVPS)
    api.GET("/rates", s.handleGetRates)
    
    // 需要认证的路由
    auth := api.Group("/")
    auth.Use(middleware.AuthMiddleware(s.cfg))
    {
        auth.POST("/vps", s.handleCreateVPS)
        auth.PUT("/vps/:id", s.handleUpdateVPS)
        auth.DELETE("/vps/:id", s.handleDeleteVPS)
    }
}

func (s *Server) Run() error {
    return s.router.Run(fmt.Sprintf("%s:%d", s.cfg.Server.Host, s.cfg.Server.Port))
} 