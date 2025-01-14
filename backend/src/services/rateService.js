const axios = require('axios');
const Rate = require('../models/rate');

class RateService {
  constructor() {
    this.FIXER_API_KEY = process.env.FIXER_API_KEY;
    this.BASE_URL = 'http://data.fixer.io/api';
  }

  async updateRates() {
    try {
      const response = await axios.get(`${this.BASE_URL}/latest`, {
        params: {
          access_key: this.FIXER_API_KEY,
          symbols: 'CNY,USD,GBP,CAD,JPY'
        }
      });

      if (response.data.success) {
        await Rate.findOneAndUpdate(
          {},
          {
            rates: response.data.rates,
            lastUpdated: new Date()
          },
          { upsert: true }
        );
        return true;
      }
      return false;
    } catch (error) {
      console.error('更新汇率失败:', error);
      return false;
    }
  }

  async convertToCNY(amount, fromCurrency) {
    const rate = await Rate.findOne();
    if (!rate) {
      throw new Error('汇率数据不可用');
    }

    if (fromCurrency === 'CNY') return amount;
    
    const eurAmount = amount / rate.rates[fromCurrency];
    return eurAmount * rate.rates.CNY;
  }
}

module.exports = new RateService(); 