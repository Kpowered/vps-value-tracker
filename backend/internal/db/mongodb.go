package db

import (
    "context"
    "time"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
    "github.com/Kpowered/vps-value-tracker/internal/config"
    "go.mongodb.org/mongo-driver/bson"
    "golang.org/x/crypto/bcrypt"
    "github.com/Kpowered/vps-value-tracker/internal/model"
)

type MongoDB struct {
    client *mongo.Client
    db     *mongo.Database
}

func NewMongoDB(cfg *config.Config) (*MongoDB, error) {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    client, err := mongo.Connect(ctx, options.Client().ApplyURI(cfg.MongoDB.URI))
    if err != nil {
        return nil, err
    }

    if err := client.Ping(ctx, nil); err != nil {
        return nil, err
    }

    return &MongoDB{
        client: client,
        db:     client.Database("vps-tracker"),
    }, nil
}

func (m *MongoDB) VPS() *mongo.Collection {
    return m.db.Collection("vps")
}

func (m *MongoDB) Rates() *mongo.Collection {
    return m.db.Collection("rates")
}

func (m *MongoDB) Users() *mongo.Collection {
    return m.db.Collection("users")
}

func (m *MongoDB) InitializeCollections() error {
    // 创建用户名索引
    _, err := m.Users().Indexes().CreateOne(context.Background(), mongo.IndexModel{
        Keys: bson.D{{Key: "username", Value: 1}},
        Options: options.Index().SetUnique(true),
    })
    if err != nil {
        return err
    }

    // 创建默认管理员用户
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
    if err != nil {
        return err
    }

    _, err = m.Users().InsertOne(context.Background(), model.User{
        Username: "admin",
        Password: string(hashedPassword),
    })
    if err != nil && !mongo.IsDuplicateKeyError(err) {
        return err
    }

    return nil
}

func (m *MongoDB) Close() error {
    return m.client.Disconnect(context.Background())
} 