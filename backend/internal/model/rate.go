package model

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type Rate struct {
    ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Base        string            `bson:"base" json:"base"`
    Rates       map[string]float64 `bson:"rates" json:"rates"`
    LastUpdated time.Time         `bson:"last_updated" json:"lastUpdated"`
} 