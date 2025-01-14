package config

import (
    "github.com/spf13/viper"
)

type Config struct {
    Server   ServerConfig   `mapstructure:"server"`
    MongoDB  MongoDBConfig  `mapstructure:"mongodb"`
    JWT      JWTConfig      `mapstructure:"jwt"`
    Fixer    FixerConfig    `mapstructure:"fixer"`
}

type ServerConfig struct {
    Port int    `mapstructure:"port"`
    Host string `mapstructure:"host"`
}

type MongoDBConfig struct {
    URI string `mapstructure:"uri"`
}

type JWTConfig struct {
    Secret string `mapstructure:"secret"`
    Expiry string `mapstructure:"expiry"`
}

type FixerConfig struct {
    APIKey  string `mapstructure:"api_key"`
    BaseURL string `mapstructure:"base_url"`
}

func Load() (*Config, error) {
    viper.SetConfigName("app")
    viper.SetConfigType("yaml")
    viper.AddConfigPath("./configs")
    viper.AddConfigPath(".")

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    var config Config
    if err := viper.Unmarshal(&config); err != nil {
        return nil, err
    }

    return &config, nil
} 