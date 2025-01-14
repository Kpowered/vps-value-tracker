package model

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type VPS struct {
    ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    MerchantName string            `bson:"merchant_name" json:"merchantName"`
    CPU          CPU               `bson:"cpu" json:"cpu"`
    Memory       Resource          `bson:"memory" json:"memory"`
    Storage      Resource          `bson:"storage" json:"storage"`
    Bandwidth    Resource          `bson:"bandwidth" json:"bandwidth"`
    Price        Price             `bson:"price" json:"price"`
    StartDate    time.Time         `bson:"start_date" json:"startDate"`
    EndDate      time.Time         `bson:"end_date" json:"endDate"`
    CreatedAt    time.Time         `bson:"created_at" json:"createdAt"`
}

type CPU struct {
    Cores int    `bson:"cores" json:"cores"`
    Model string `bson:"model" json:"model"`
}

type Resource struct {
    Size int    `bson:"size" json:"size"`
    Type string `bson:"type" json:"type"`
}

type Price struct {
    Amount    float64 `bson:"amount" json:"amount"`
    Currency  string  `bson:"currency" json:"currency"`
    CNYAmount float64 `bson:"cny_amount" json:"cnyAmount"`
} 