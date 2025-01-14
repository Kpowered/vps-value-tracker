export interface VPS {
  id: string
  provider: string
  price: number
  currency: 'CNY' | 'USD' | 'EUR' | 'GBP' | 'CAD' | 'JPY'
  startDate: Date
  endDate: Date
  cpu: {
    cores: number
    model: string
  }
  memory: {
    size: number
    type: string
  }
  storage: {
    size: number
    type: string
  }
  bandwidth: {
    amount: number
    type: string
  }
  priceInCNY: number
  remainingValue: number
  remainingValueCNY: number
}

export interface VPSForm {
  provider: string
  price: number
  currency: string
  startDate: Date
  endDate: Date
  cpu: {
    cores: number
    model: string
  }
  memory: {
    size: number
    type: string
  }
  storage: {
    size: number
    type: string
  }
  bandwidth: {
    amount: number
    type: string
  }
} 