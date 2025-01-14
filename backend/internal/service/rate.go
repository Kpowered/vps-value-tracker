package service

import (
    "encoding/json"
    "fmt"
    "net/http"
    "time"
    "github.com/Kpowered/vps-value-tracker/internal/model"
    "github.com/Kpowered/vps-value-tracker/internal/config"
)

type RateService struct {
    cfg *config.Config
}

func NewRateService(cfg *config.Config) *RateService {
    return &RateService{cfg: cfg}
}

type FixerResponse struct {
    Success bool               `json:"success"`
    Rates   map[string]float64 `json:"rates"`
}

func (s *RateService) UpdateRates() (*model.Rate, error) {
    url := fmt.Sprintf("%s/latest?access_key=%s&symbols=CNY,USD,GBP,CAD,JPY", 
        s.cfg.Fixer.BaseURL, s.cfg.Fixer.APIKey)

    resp, err := http.Get(url)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var fixerResp FixerResponse
    if err := json.NewDecoder(resp.Body).Decode(&fixerResp); err != nil {
        return nil, err
    }

    if !fixerResp.Success {
        return nil, fmt.Errorf("fixer API request failed")
    }

    rate := &model.Rate{
        Base:        "EUR",
        Rates:       fixerResp.Rates,
        LastUpdated: time.Now(),
    }

    return rate, nil
} 