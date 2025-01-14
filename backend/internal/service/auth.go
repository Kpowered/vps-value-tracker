package service

import (
    "context"
    "errors"
    "time"
    "github.com/golang-jwt/jwt"
    "golang.org/x/crypto/bcrypt"
    "github.com/Kpowered/vps-value-tracker/internal/model"
    "github.com/Kpowered/vps-value-tracker/internal/config"
    "github.com/Kpowered/vps-value-tracker/internal/db"
    "go.mongodb.org/mongo-driver/bson"
)

type AuthService struct {
    db  *db.MongoDB
    cfg *config.Config
}

func NewAuthService(db *db.MongoDB, cfg *config.Config) *AuthService {
    return &AuthService{db: db, cfg: cfg}
}

func (s *AuthService) Login(username, password string) (string, error) {
    var user model.User
    err := s.db.Users().FindOne(context.Background(), bson.M{"username": username}).Decode(&user)
    if err != nil {
        return "", errors.New("invalid credentials")
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
        return "", errors.New("invalid credentials")
    }

    // 生成JWT令牌
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "user_id": user.ID.Hex(),
        "exp":     time.Now().Add(24 * time.Hour).Unix(),
    })

    tokenString, err := token.SignedString([]byte(s.cfg.JWT.Secret))
    if err != nil {
        return "", err
    }

    return tokenString, nil
} 