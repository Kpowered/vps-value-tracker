import axios from 'axios';
import { Redis } from 'ioredis';

interface ExchangeRateResponse {
  success: boolean;
  timestamp: number;
  base: string;
  date: string;
  rates: Record<string, number>;
}

export class ExchangeRateService {
  private readonly API_KEY = 'e65a0dbfc190ce964f2771bca5c08e13';
  private readonly BASE_URL = 'http://data.fixer.io/api';
  private readonly CACHE_KEY = 'exchange_rates';
  private readonly CACHE_EXPIRY = 86400; // 24小时缓存
  private readonly SUPPORTED_CURRENCIES = ['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY'];
  
  constructor(private readonly redis: Redis) {}

  /**
   * 获取最新汇率数据
   * 优先从Redis缓存获取，如果缓存不存在或过期则从API获取
   */
  async getRates(): Promise<Record<string, number>> {
    try {
      // 尝试从缓存获取
      const cachedRates = await this.redis.get(this.CACHE_KEY);
      if (cachedRates) {
        return JSON.parse(cachedRates);
      }

      // 从API获取新数据
      const response = await axios.get<ExchangeRateResponse>(
        `${this.BASE_URL}/latest`,
        {
          params: {
            access_key: this.API_KEY,
            base: 'EUR',
            symbols: this.SUPPORTED_CURRENCIES.join(',')
          }
        }
      );

      if (!response.data.success) {
        throw new Error('API request failed');
      }

      // 缓存数据
      await this.redis.set(
        this.CACHE_KEY,
        JSON.stringify(response.data.rates),
        'EX',
        this.CACHE_EXPIRY
      );

      return response.data.rates;
    } catch (error) {
      // 如果API请求失败，尝试使用缓存的旧数据
      const cachedRates = await this.redis.get(this.CACHE_KEY);
      if (cachedRates) {
        return JSON.parse(cachedRates);
      }
      throw new Error('Failed to fetch exchange rates and no cached data available');
    }
  }

  /**
   * 将任意支持的货币转换为人民币
   * @param amount 金额
   * @param currency 货币代码
   * @returns 转换后的人民币金额
   */
  async convertToCNY(amount: number, currency: string): Promise<number> {
    if (!this.SUPPORTED_CURRENCIES.includes(currency)) {
      throw new Error(`Unsupported currency: ${currency}`);
    }

    if (currency === 'CNY') {
      return amount;
    }

    const rates = await this.getRates();
    
    if (!rates['CNY'] || !rates[currency]) {
      throw new Error('Required exchange rates not available');
    }

    // 由于fixer.io的免费版本只支持以EUR为基准，所以需要通过EUR进行转换
    if (currency === 'EUR') {
      return Number((amount * rates['CNY']).toFixed(2));
    }

    // 先转换为EUR，再转换为CNY
    const amountInEUR = amount / rates[currency];
    return Number((amountInEUR * rates['CNY']).toFixed(2));
  }

  /**
   * 获取所有支持货币对CNY的汇率
   * @returns 汇率对象，key为货币代码，value为对CNY的汇率
   */
  async getAllCNYRates(): Promise<Record<string, number>> {
    const rates = await this.getRates();
    const cnyRates: Record<string, number> = {};

    for (const currency of this.SUPPORTED_CURRENCIES) {
      if (currency === 'CNY') {
        cnyRates[currency] = 1;
      } else if (currency === 'EUR') {
        cnyRates[currency] = Number(rates['CNY'].toFixed(4));
      } else {
        cnyRates[currency] = Number((rates['CNY'] / rates[currency]).toFixed(4));
      }
    }

    return cnyRates;
  }
} 