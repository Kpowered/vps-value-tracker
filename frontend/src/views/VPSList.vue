<template>
  <div class="vps-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>VPS 列表</span>
          <el-button v-if="authStore.isAuthenticated" type="primary" @click="$router.push('/add')">
            添加 VPS
          </el-button>
        </div>
      </template>

      <el-table :data="vpsList" stripe>
        <el-table-column prop="provider" label="服务商" />
        <el-table-column prop="cpu.cores" label="CPU核心数" />
        <el-table-column prop="memory.size" label="内存(GB)" />
        <el-table-column prop="storage.size" label="硬盘(GB)" />
        <el-table-column prop="bandwidth.amount" label="流量(GB)" />
        <el-table-column label="价格">
          <template #default="{ row }">
            {{ row.price }} {{ row.currency }}
            <br>
            <small>(￥{{ row.priceInCNY }})</small>
          </template>
        </el-table-column>
        <el-table-column label="剩余价值">
          <template #default="{ row }">
            {{ row.remainingValue }} {{ row.currency }}
            <br>
            <small>(￥{{ row.remainingValueCNY }})</small>
          </template>
        </el-table-column>
        <el-table-column label="到期时间">
          <template #default="{ row }">
            {{ new Date(row.endDate).toLocaleDateString() }}
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { api } from '../utils/api'

const authStore = useAuthStore()
const vpsList = ref([])

const fetchVPSList = async () => {
  try {
    const { data } = await api.get('/vps')
    vpsList.value = data
  } catch (error) {
    console.error('Failed to fetch VPS list:', error)
  }
}

onMounted(fetchVPSList)
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style> 