package models

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type VPS struct {
    ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Provider  string            `bson:"provider" json:"provider"`
    Price     float64           `bson:"price" json:"price"`
    Currency  string            `bson:"currency" json:"currency"`
    StartDate time.Time         `bson:"startDate" json:"startDate"`
    EndDate   time.Time         `bson:"endDate" json:"endDate"`
    Specs     string            `bson:"specs" json:"specs"`
} 