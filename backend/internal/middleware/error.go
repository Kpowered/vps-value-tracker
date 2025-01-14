package middleware

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

func ErrorHandler() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Next()

        // 只处理第一个错误
        if len(c.Errors) > 0 {
            err := c.Errors[0].Err
            switch e := err.(type) {
            case *ValidationError:
                c.JSON(http.StatusBadRequest, gin.H{
                    "error": e.Error(),
                })
            case *AuthError:
                c.JSON(http.StatusUnauthorized, gin.H{
                    "error": e.Error(),
                })
            default:
                c.JSON(http.StatusInternalServerError, gin.H{
                    "error": "Internal Server Error",
                })
            }
        }
    }
}

type ValidationError struct {
    Message string
}

func (e *ValidationError) Error() string {
    return e.Message
}

type AuthError struct {
    Message string
}

func (e *AuthError) Error() string {
    return e.Message
} 