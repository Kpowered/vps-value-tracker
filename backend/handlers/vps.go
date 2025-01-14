package handlers

import (
    "context"
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "vps-tracker/models"
)

func (h *Handler) ListVPS(c *gin.Context) {
    var vpsList []models.VPS
    cursor, err := h.db.Collection("vps").Find(context.Background(), bson.M{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching VPS list"})
        return
    }
    defer cursor.Close(context.Background())

    if err := cursor.All(context.Background(), &vpsList); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error decoding VPS list"})
        return
    }

    c.JSON(http.StatusOK, vpsList)
}

func (h *Handler) CreateVPS(c *gin.Context) {
    var vps models.VPS
    if err := c.ShouldBindJSON(&vps); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    vps.StartDate = time.Now()
    vps.EndDate = vps.StartDate.AddDate(1, 0, 0)

    result, err := h.db.Collection("vps").InsertOne(context.Background(), vps)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creating VPS"})
        return
    }

    vps.ID = result.InsertedID.(primitive.ObjectID)
    c.JSON(http.StatusCreated, vps)
}

func (h *Handler) UpdateVPS(c *gin.Context) {
    id, err := primitive.ObjectIDFromHex(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
        return
    }

    var vps models.VPS
    if err := c.ShouldBindJSON(&vps); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    result, err := h.db.Collection("vps").UpdateOne(
        context.Background(),
        bson.M{"_id": id},
        bson.M{"$set": vps},
    )
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error updating VPS"})
        return
    }

    if result.MatchedCount == 0 {
        c.JSON(http.StatusNotFound, gin.H{"error": "VPS not found"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "VPS updated successfully"})
}

func (h *Handler) DeleteVPS(c *gin.Context) {
    id, err := primitive.ObjectIDFromHex(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
        return
    }

    result, err := h.db.Collection("vps").DeleteOne(context.Background(), bson.M{"_id": id})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error deleting VPS"})
        return
    }

    if result.DeletedCount == 0 {
        c.JSON(http.StatusNotFound, gin.H{"error": "VPS not found"})
        return
    }

    c.JSON(http.StatusNoContent, nil)
} 