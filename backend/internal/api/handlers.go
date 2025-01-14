package api

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/Kpowered/vps-value-tracker/internal/model"
    "github.com/Kpowered/vps-value-tracker/internal/utils"
    "time"
)

// VPS处理器
func (s *Server) handleGetAllVPS(c *gin.Context) {
    vpsList, err := s.vps.GetAll()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // 计算每个VPS的剩余价值
    var response []map[string]interface{}
    for _, vps := range vpsList {
        remainingDays := getRemainingDays(vps.EndDate)
        remainingValue := (vps.Price.Amount * float64(remainingDays)) / 365
        remainingCNYValue := (vps.Price.CNYAmount * float64(remainingDays)) / 365

        vpsData := gin.H{
            "vps": vps,
            "remainingValue": gin.H{
                "original": gin.H{
                    "amount":   remainingValue,
                    "currency": vps.Price.Currency,
                },
                "cny": remainingCNYValue,
            },
        }
        response = append(response, vpsData)
    }

    c.JSON(http.StatusOK, response)
}

func (s *Server) handleCreateVPS(c *gin.Context) {
    var vps model.VPS
    if err := c.ShouldBindJSON(&vps); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    if err := s.vps.Create(&vps); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, vps)
}

func (s *Server) handleUpdateVPS(c *gin.Context) {
    id := c.Param("id")
    var vps model.VPS
    if err := c.ShouldBindJSON(&vps); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    if err := s.vps.Update(id, &vps); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, vps)
}

func (s *Server) handleDeleteVPS(c *gin.Context) {
    id := c.Param("id")
    if err := s.vps.Delete(id); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "VPS deleted successfully"})
}

// 汇率处理器
func (s *Server) handleGetRates(c *gin.Context) {
    rates, err := s.rates.UpdateRates()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, rates)
}

func getRemainingDays(endDate time.Time) int {
    return utils.GetRemainingDays(endDate)
} 