import { Request, Response } from 'express';
import VPS from '../models/VPS';
import { ExchangeRateService } from '../services/ExchangeRateService';

export class VPSController {
  private exchangeRateService: ExchangeRateService;

  constructor(exchangeRateService: ExchangeRateService) {
    this.exchangeRateService = exchangeRateService;
  }

  async create(req: Request, res: Response) {
    try {
      const vpsData = req.body;
      
      // 转换价格为人民币
      const priceInCNY = await this.exchangeRateService.convertToCNY(
        vpsData.price,
        vpsData.currency
      );

      // 计算剩余价值
      const now = new Date();
      const endDate = new Date(vpsData.endDate);
      const totalDays = 365;
      const remainingDays = Math.max(0, Math.ceil((endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
      const remainingValue = priceInCNY * (remainingDays / totalDays);

      const vps = new VPS({
        ...vpsData,
        priceInCNY,
        remainingValue
      });

      await vps.save();
      res.status(201).json(vps);
    } catch (error) {
      res.status(500).json({ error: 'Failed to create VPS entry' });
    }
  }

  async list(req: Request, res: Response) {
    try {
      const vpsList = await VPS.find();
      
      // 更新所有VPS的剩余价值
      const now = new Date();
      const updatedVPSList = await Promise.all(
        vpsList.map(async (vps) => {
          const remainingDays = Math.max(0, Math.ceil((vps.endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
          vps.remainingValue = vps.priceInCNY * (remainingDays / 365);
          await vps.save();
          return vps;
        })
      );

      res.json(updatedVPSList);
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch VPS list' });
    }
  }
} 