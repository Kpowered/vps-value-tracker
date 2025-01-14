const VPS = require('../models/vps');
const rateService = require('../services/rateService');

class VPSController {
  async create(req, res) {
    try {
      const {
        merchantName,
        cpu,
        memory,
        storage,
        bandwidth,
        price,
      } = req.body;

      // 转换价格为人民币
      const cnyAmount = await rateService.convertToCNY(price.amount, price.currency);

      // 设置开始时间和结束时间
      const startDate = new Date();
      const endDate = new Date();
      endDate.setFullYear(endDate.getFullYear() + 1);

      const vps = new VPS({
        merchantName,
        cpu,
        memory,
        storage,
        bandwidth,
        price: {
          ...price,
          cnyAmount
        },
        startDate,
        endDate
      });

      await vps.save();
      res.status(201).json(vps);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  async getAll(req, res) {
    try {
      const vpsList = await VPS.find();
      
      // 计算每个VPS的剩余价值
      const vpsWithValue = vpsList.map(vps => {
        const now = new Date();
        const daysRemaining = Math.max(0, 
          Math.ceil((vps.endDate - now) / (1000 * 60 * 60 * 24))
        );
        const remainingValue = (vps.price.cnyAmount * daysRemaining) / 365;

        return {
          ...vps.toObject(),
          remainingValue: {
            original: {
              amount: (vps.price.amount * daysRemaining) / 365,
              currency: vps.price.currency
            },
            cny: remainingValue
          }
        };
      });

      res.json(vpsWithValue);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new VPSController(); 