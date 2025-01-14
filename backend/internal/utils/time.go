package utils

import (
    "math"
    "time"
)

// GetRemainingDays 计算剩余天数
func GetRemainingDays(endDate time.Time) int {
    now := time.Now()
    if endDate.Before(now) {
        return 0
    }
    days := endDate.Sub(now).Hours() / 24
    return int(math.Ceil(days))
}

// ConvertToGB 将不同单位转换为GB
func ConvertToGB(size float64, unit string) int {
    switch unit {
    case "TB":
        return int(size * 1024)
    case "MB":
        return int(size / 1024)
    default: // GB
        return int(size)
    }
} 