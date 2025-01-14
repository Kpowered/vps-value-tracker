const mongoose = require('mongoose');

const vpsSchema = new mongoose.Schema({
  merchantName: { type: String, required: true },
  cpu: {
    cores: { type: Number, required: true },
    model: { type: String }
  },
  memory: {
    size: { type: Number, required: true }, // GB
    type: { type: String }
  },
  storage: {
    size: { type: Number, required: true }, // GB
    type: { type: String }
  },
  bandwidth: {
    size: { type: Number, required: true }, // GB
    type: { type: String }
  },
  price: {
    amount: { type: Number, required: true },
    currency: { type: String, required: true },
    cnyAmount: { type: Number, required: true } // 转换后的人民币金额
  },
  startDate: { type: Date, default: Date.now },
  endDate: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('VPS', vpsSchema); 