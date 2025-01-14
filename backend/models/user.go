package models

import (
    "golang.org/x/crypto/bcrypt"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
    ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Username string            `bson:"username" json:"username"`
    Password string            `bson:"password" json:"-"`
}

func (u *User) HashPassword() error {
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(u.Password), bcrypt.DefaultCost)
    if err != nil {
        return err
    }
    u.Password = string(hashedPassword)
    return nil
}

func (u *User) ComparePassword(password string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
    return err == nil
} 