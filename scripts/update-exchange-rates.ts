import { updateExchangeRates } from '@/lib/exchange-rate'

async function main() {
  try {
    await updateExchangeRates()
    process.exit(0)
  } catch (error) {
    console.error('Failed to update exchange rates:', error)
    process.exit(1)
  }
}

main() 