const mongoose = require('mongoose');

const rateSchema = new mongoose.Schema({
  base: { type: String, default: 'EUR' },
  rates: {
    CNY: Number,
    USD: Number,
    GBP: Number,
    CAD: Number,
    JPY: Number
  },
  lastUpdated: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Rate', rateSchema); 