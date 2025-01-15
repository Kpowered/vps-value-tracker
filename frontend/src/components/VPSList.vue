<template>
  <div class="vps-list">
    <div v-for="vps in vpsList" :key="vps.id" class="vps-card">
      <h3>{{ vps.vendor }}</h3>
      <div class="specs">
        <p>CPU: {{ vps.cpu_cores }}核 {{ vps.cpu_model }}</p>
        <p>内存: {{ vps.memory_gb }}GB</p>
        <p>硬盘: {{ vps.disk_gb }}GB</p>
        <p>流量: {{ vps.bandwidth_gb }}GB</p>
      </div>
      <div class="value">
        <p>原价: {{ vps.price }} {{ vps.currency }}</p>
        <p>剩余价值: {{ formatValue(vps.remaining_value) }} {{ vps.currency }}</p>
        <p>约合人民币: ¥{{ formatValue(vps.remaining_value_cny) }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface VPS {
  id: number
  vendor: string
  cpu_cores: number
  cpu_model: string
  memory_gb: number
  disk_gb: number
  bandwidth_gb: number
  price: number
  currency: string
  remaining_value: number
  remaining_value_cny: number
}

const vpsList = ref<VPS[]>([])

const formatValue = (value: number) => {
  return value.toFixed(2)
}

const fetchVPSList = async () => {
  try {
    const response = await axios.get('/api/vps')
    vpsList.value = response.data.vps_list
  } catch (error) {
    console.error('获取VPS列表失败:', error)
  }
}

onMounted(fetchVPSList)
</script>

<style>
.vps-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  padding: 1rem;
}

.vps-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1rem;
  background: white;
}

.specs {
  margin: 1rem 0;
}

.value {
  border-top: 1px solid #eee;
  padding-top: 1rem;
}
</style> 