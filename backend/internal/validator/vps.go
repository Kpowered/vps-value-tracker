package validator

import (
    "errors"
    "github.com/Kpowered/vps-value-tracker/internal/model"
    "github.com/Kpowered/vps-value-tracker/internal/utils"
)

func ValidateVPS(vps *model.VPS) error {
    if vps.MerchantName == "" {
        return errors.New("merchant name is required")
    }

    // CPU验证
    if vps.CPU.Cores < 1 {
        return errors.New("cpu cores must be greater than 0")
    }

    // 内存验证
    if vps.Memory.Size < 1 {
        return errors.New("memory size must be greater than 0")
    }

    // 硬盘验证
    if vps.Storage.Size < 1 {
        return errors.New("storage size must be greater than 0")
    }

    // 带宽验证
    if vps.Bandwidth.Size < 1 {
        return errors.New("bandwidth size must be greater than 0")
    }

    // 价格验证
    if vps.Price.Amount <= 0 {
        return errors.New("price amount must be greater than 0")
    }

    // 货币验证
    if !isValidCurrency(vps.Price.Currency) {
        return errors.New("invalid currency")
    }

    // 转换单位为GB
    vps.Memory.Size = utils.ConvertToGB(float64(vps.Memory.Size), vps.Memory.Type)
    vps.Storage.Size = utils.ConvertToGB(float64(vps.Storage.Size), vps.Storage.Type)
    vps.Bandwidth.Size = utils.ConvertToGB(float64(vps.Bandwidth.Size), vps.Bandwidth.Type)

    return nil
}

func isValidCurrency(currency string) bool {
    validCurrencies := map[string]bool{
        "CNY": true,
        "USD": true,
        "EUR": true,
        "GBP": true,
        "CAD": true,
        "JPY": true,
    }
    return validCurrencies[currency]
} 