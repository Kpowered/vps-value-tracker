package handlers

import (
    "context"
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "go.mongodb.org/mongo-driver/bson"
    "vps-tracker/models"
)

func (h *Handler) Register(c *gin.Context) {
    var user models.User
    if err := c.ShouldBindJSON(&user); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // 检查用户名是否已存在
    exists, err := h.db.Collection("users").CountDocuments(
        context.Background(),
        bson.M{"username": user.Username},
    )
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error checking username"})
        return
    }
    if exists > 0 {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Username already exists"})
        return
    }

    // 加密密码
    if err := user.HashPassword(); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error hashing password"})
        return
    }

    // 保存用户
    _, err = h.db.Collection("users").InsertOne(context.Background(), user)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creating user"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"message": "User registered successfully"})
}

func (h *Handler) Login(c *gin.Context) {
    var login struct {
        Username string `json:"username" binding:"required"`
        Password string `json:"password" binding:"required"`
    }

    if err := c.ShouldBindJSON(&login); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    var user models.User
    err := h.db.Collection("users").FindOne(context.Background(), 
        bson.M{"username": login.Username}).Decode(&user)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }

    if !user.ComparePassword(login.Password) {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "id":       user.ID.Hex(),
        "username": user.Username,
        "exp":      time.Now().Add(time.Hour * 24).Unix(),
    })

    tokenString, err := token.SignedString([]byte(h.config.JWTSecret))
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"token": tokenString})
}

func (h *Handler) InitAdmin() error {
    ctx := context.Background()
    count, err := h.db.Collection("users").CountDocuments(ctx, bson.M{"username": "admin"})
    if err != nil {
        return err
    }

    if count == 0 {
        admin := models.User{
            Username: "admin",
            Password: "admin123456",
        }
        if err := admin.HashPassword(); err != nil {
            return err
        }

        _, err = h.db.Collection("users").InsertOne(ctx, admin)
        return err
    }

    return nil
} 