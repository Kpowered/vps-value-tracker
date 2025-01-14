<template>
  <div class="rate-display">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>当前汇率</span>
          <el-tag size="small" type="info">
            更新时间: {{ formatDate(rates.lastUpdated) }}
          </el-tag>
        </div>
      </template>
      
      <div class="rates-grid">
        <div v-for="(rate, currency) in rates.rates" :key="currency" class="rate-item">
          <div class="currency-name">
            {{ getCurrencyName(currency) }}
            <span class="currency-code">({{ currency }})</span>
          </div>
          <div class="rate-value">
            <span class="base">1 EUR = </span>
            <span class="amount">{{ formatRate(rate) }}</span>
          </div>
        </div>
      </div>

      <div class="refresh-section">
        <el-button 
          type="primary" 
          :loading="loading"
          size="small"
          @click="refreshRates"
        >
          刷新汇率
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { rateAPI } from '../api/rate';

const rates = ref({
  base: 'EUR',
  rates: {},
  lastUpdated: null
});

const loading = ref(false);

const currencyNames = {
  CNY: '人民币',
  USD: '美元',
  EUR: '欧元',
  GBP: '英镑',
  CAD: '加元',
  JPY: '日元'
};

const getCurrencyName = (code) => currencyNames[code] || code;

const formatDate = (date) => {
  if (!date) return '未知';
  return new Date(date).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const formatRate = (rate) => {
  return rate.toFixed(4);
};

const loadRates = async () => {
  try {
    loading.value = true;
    const data = await rateAPI.getLatest();
    rates.value = data;
  } catch (error) {
    ElMessage.error('获取汇率失败');
  } finally {
    loading.value = false;
  }
};

const refreshRates = () => {
  loadRates();
};

onMounted(() => {
  loadRates();
});
</script>

<style scoped>
.rate-display {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.rates-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 20px;
}

.rate-item {
  padding: 10px;
  border-radius: 4px;
  background-color: var(--background-color);
  transition: background-color 0.3s;
}

.rate-item:hover {
  background-color: #eef1f6;
}

.currency-name {
  font-weight: 500;
  margin-bottom: 5px;
}

.currency-code {
  color: var(--info-color);
  font-size: 0.9em;
}

.rate-value {
  font-size: 1.1em;
}

.base {
  color: var(--info-color);
}

.amount {
  font-weight: 500;
  color: var(--primary-color);
}

.refresh-section {
  text-align: center;
  margin-top: 20px;
}
</style> 