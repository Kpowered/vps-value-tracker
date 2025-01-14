package service

import (
    "context"
    "time"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "github.com/Kpowered/vps-value-tracker/internal/model"
    "github.com/Kpowered/vps-value-tracker/internal/db"
    "github.com/Kpowered/vps-value-tracker/internal/validator"
)

type VPSService struct {
    db    *db.MongoDB
    rates *RateService
}

func NewVPSService(db *db.MongoDB, rates *RateService) *VPSService {
    return &VPSService{
        db:    db,
        rates: rates,
    }
}

func (s *VPSService) Create(vps *model.VPS) error {
    // 验证VPS数据
    if err := validator.ValidateVPS(vps); err != nil {
        return &ValidationError{Message: err.Error()}
    }

    // 设置开始时间和结束时间
    vps.StartDate = time.Now()
    vps.EndDate = vps.StartDate.AddDate(1, 0, 0)
    vps.CreatedAt = time.Now()

    // 获取最新汇率并转换价格
    rate, err := s.rates.UpdateRates()
    if err != nil {
        return err
    }

    // 转换为人民币
    if vps.Price.Currency != "CNY" {
        eurRate := rate.Rates[vps.Price.Currency]
        cnyRate := rate.Rates["CNY"]
        vps.Price.CNYAmount = (vps.Price.Amount / eurRate) * cnyRate
    } else {
        vps.Price.CNYAmount = vps.Price.Amount
    }

    _, err = s.db.VPS().InsertOne(context.Background(), vps)
    return err
}

func (s *VPSService) GetAll() ([]*model.VPS, error) {
    cursor, err := s.db.VPS().Find(context.Background(), bson.M{})
    if err != nil {
        return nil, err
    }
    defer cursor.Close(context.Background())

    var vpsList []*model.VPS
    if err := cursor.All(context.Background(), &vpsList); err != nil {
        return nil, err
    }

    return vpsList, nil
}

func (s *VPSService) Update(id string, vps *model.VPS) error {
    objID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return err
    }

    // 更新价格转换
    rate, err := s.rates.UpdateRates()
    if err != nil {
        return err
    }

    if vps.Price.Currency != "CNY" {
        eurRate := rate.Rates[vps.Price.Currency]
        cnyRate := rate.Rates["CNY"]
        vps.Price.CNYAmount = (vps.Price.Amount / eurRate) * cnyRate
    } else {
        vps.Price.CNYAmount = vps.Price.Amount
    }

    _, err = s.db.VPS().UpdateOne(
        context.Background(),
        bson.M{"_id": objID},
        bson.M{"$set": vps},
    )
    return err
}

func (s *VPSService) Delete(id string) error {
    objID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return err
    }

    _, err = s.db.VPS().DeleteOne(context.Background(), bson.M{"_id": objID})
    return err
} 