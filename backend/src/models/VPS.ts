import mongoose, { Schema, Document } from 'mongoose';

export interface IVPS extends Document {
  provider: string;
  price: number;
  currency: string;
  startDate: Date;
  endDate: Date;
  specs: string;
}

const VPSSchema: Schema = new Schema({
  provider: {
    type: String,
    required: true
  },
  price: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    required: true,
    enum: ['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY']
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  specs: {
    type: String,
    required: true
  }
});

export const VPS = mongoose.model<IVPS>('VPS', VPSSchema); 