import mongoose, { Schema, Document } from 'mongoose';

export interface IVPS extends Document {
  provider: string;
  price: number;
  currency: string;
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
  cpu: {
    cores: {
      type: Number,
      required: true
    },
    model: {
      type: String,
      required: true
    }
  },
  memory: {
    size: {
      type: Number,
      required: true
    },
    type: {
      type: String,
      default: 'DDR4'
    }
  },
  storage: {
    size: {
      type: Number,
      required: true
    },
    type: {
      type: String,
      default: 'SSD'
    }
  },
  bandwidth: {
    amount: {
      type: Number,
      required: true
    },
    type: {
      type: String,
      default: 'Monthly'
    }
  }
});

export const VPS = mongoose.model<IVPS>('VPS', VPSSchema); 