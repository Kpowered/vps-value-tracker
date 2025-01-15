<template>
  <div class="vps-form">
    <form @submit.prevent="submitVPS">
      <input v-model="form.vendor" placeholder="商家名称" required>
      
      <div class="cpu-input">
        <input v-model.number="form.cpu_cores" type="number" placeholder="CPU核心数" required>
        <input v-model="form.cpu_model" placeholder="CPU型号" required>
      </div>

      <input v-model.number="form.memory_gb" type="number" placeholder="内存(GB)" required>
      <input v-model.number="form.disk_gb" type="number" placeholder="硬盘(GB)" required>
      <input v-model.number="form.bandwidth_gb" type="number" placeholder="流量(GB)" required>
      
      <div class="price-input">
        <input v-model.number="form.price" type="number" step="0.01" placeholder="价格" required>
        <select v-model="form.currency">
          <option value="CNY">人民币</option>
          <option value="USD">美元</option>
          <option value="EUR">欧元</option>
          <option value="GBP">英镑</option>
          <option value="CAD">加元</option>
          <option value="JPY">日元</option>
        </select>
      </div>

      <button type="submit">添加VPS</button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import axios from 'axios'

const form = ref({
  vendor: '',
  cpu_cores: 1,
  cpu_model: '',
  memory_gb: 1,
  disk_gb: 1,
  bandwidth_gb: 1,
  price: 0,
  currency: 'CNY'
})

const submitVPS = async () => {
  try {
    await axios.post('/api/vps', form.value)
    // 重置表单
    form.value = {
      vendor: '',
      cpu_cores: 1,
      cpu_model: '',
      memory_gb: 1,
      disk_gb: 1,
      bandwidth_gb: 1,
      price: 0,
      currency: 'CNY'
    }
  } catch (error) {
    console.error('添加VPS失败:', error)
  }
}
</script>

<style>
.vps-form {
  max-width: 600px;
  margin: 0 auto;
  padding: 1rem;
}

form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

input, select {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

button {
  padding: 0.5rem;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:hover {
  background: #45a049;
}
</style> 