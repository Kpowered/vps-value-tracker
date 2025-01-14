package config

import "os"

type Config struct {
    DBUrl      string
    JWTSecret  string
    ListenAddr string
}

func Load() *Config {
    return &Config{
        DBUrl:      getEnv("DB_URL", "mongodb://localhost:27017"),
        JWTSecret:  getEnv("JWT_SECRET", "your-secret-key"),
        ListenAddr: getEnv("LISTEN_ADDR", ":3000"),
    }
}

func getEnv(key, fallback string) string {
    if value, ok := os.LookupEnv(key); ok {
        return value
    }
    return fallback
} 