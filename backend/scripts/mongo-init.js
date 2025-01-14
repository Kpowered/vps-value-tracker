db.createUser({
    user: process.env.MONGO_INITDB_ROOT_USERNAME,
    pwd: process.env.MONGO_INITDB_ROOT_PASSWORD,
    roles: [
        {
            role: "readWrite",
            db: "vps-tracker"
        }
    ]
});

db = db.getSiblingDB('vps-tracker');

// 创建集合
db.createCollection('users');
db.createCollection('vps');
db.createCollection('rates');

// 创建默认管理员用户
db.users.insertOne({
    username: "admin",
    password: "$2a$10$QOJ6lj.Z2865ZxQPrKqUB.QE2ZXGkCxZJQZu3y9MLBYhCD/fPdQJi", // admin123456
    createdAt: new Date()
});

// 创建索引
db.users.createIndex({ "username": 1 }, { unique: true });
db.vps.createIndex({ "merchantName": 1 });
db.rates.createIndex({ "base": 1 }); 