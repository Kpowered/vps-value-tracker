package handlers

import (
	"go.mongodb.org/mongo-driver/mongo"
	"vps-tracker/config"
)

type Handler struct {
	db     *mongo.Database
	config *config.Config
}

func NewHandler(db *mongo.Database, cfg *config.Config) *Handler {
	return &Handler{
		db:     db,
		config: cfg,
	}
} 