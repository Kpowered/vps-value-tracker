package api

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

type LoginRequest struct {
    Username string `json:"username"`
    Password string `json:"password"`
}

func (s *Server) handleLogin(c *gin.Context) {
    var req LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    token, err := s.auth.Login(req.Username, req.Password)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "token": token,
    })
} 