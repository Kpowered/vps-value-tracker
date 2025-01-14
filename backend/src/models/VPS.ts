import mongoose, { Schema, Document } from 'mongoose';

export interface IVPS extends Document {
  name: string;
  provider: string;
  location: string;
  price: number;
  currency: 'CNY' | 'USD' | 'EUR' | 'GBP' | 'CAD' | 'JPY';
  startDate: Date;
  endDate: Date;
  cpu: {
    cores: number;
    model: string;
  };
  memory: {
    size: number;
    type: string;
  };
  storage: {
    size: number;
    type: string;
  };
  bandwidth: {
    amount: number;
    type: string;
  };
  priceInCNY: number;
  remainingValue: number;
}

const VPSSchema: Schema = new Schema({
  name: { type: String, required: true },
  provider: { type: String, required: true },
  location: { type: String, required: true },
  price: { type: Number, required: true },
  currency: { 
    type: String, 
    required: true,
    enum: ['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY']
  },
  startDate: { type: Date, default: Date.now },
  endDate: { type: Date, required: true },
  cpu: {
    cores: { type: Number, required: true },
    model: { type: String, required: true }
  },
  memory: {
    size: { type: Number, required: true },
    type: { type: String, required: true }
  },
  storage: {
    size: { type: Number, required: true },
    type: { type: String, required: true }
  },
  bandwidth: {
    amount: { type: Number, required: true },
    type: { type: String, required: true }
  },
  priceInCNY: { type: Number, required: true },
  remainingValue: { type: Number, required: true }
});

export default mongoose.model<IVPS>('VPS', VPSSchema); 