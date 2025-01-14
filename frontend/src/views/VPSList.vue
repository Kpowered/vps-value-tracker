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

      <el-table v-loading="loading" :data="vpsList" style="width: 100%">
        <el-table-column prop="provider" label="服务商" />
        <el-table-column prop="specs" label="配置" />
        <el-table-column label="价格">
          <template #default="{ row }">
            {{ row.price }} {{ row.currency }}
          </template>
        </el-table-column>
        <el-table-column label="到期时间">
          <template #default="{ row }">
            {{ new Date(row.endDate).toLocaleDateString() }}
          </template>
        </el-table-column>
        <el-table-column label="剩余价值">
          <template #default="{ row }">
            {{ calculateRemainingValue(row) }} {{ row.currency }}
          </template>
        </el-table-column>
        <el-table-column v-if="token" label="操作" width="150">
          <template #default="{ row }">
            <el-button-group>
              <el-button
                type="danger"
                size="small"
                @click="handleDelete(row.id!)"
              >
                删除
              </el-button>
            </el-button-group>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { vpsApi, type VPS } from '@/utils/api'

const vpsList = ref<VPS[]>([])
const loading = ref(false)

const loadVPSList = async () => {
  try {
    loading.value = true
    const { data } = await vpsApi.list()
    vpsList.value = data
  } catch (error) {
    ElMessage.error('加载 VPS 列表失败')
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id: string) => {
  try {
    await ElMessageBox.confirm('确定要删除这个 VPS 吗？', '提示', {
      type: 'warning'
    })
    await vpsApi.delete(id)
    ElMessage.success('删除成功')
    loadVPSList()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const calculateRemainingValue = (vps: VPS) => {
  const now = new Date()
  const end = new Date(vps.endDate)
  const total = end.getTime() - new Date(vps.startDate).getTime()
  const remaining = end.getTime() - now.getTime()
  const ratio = Math.max(0, remaining / total)
  return (vps.price * ratio).toFixed(2)
}

onMounted(loadVPSList)
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.vps-list {
  padding: 20px;
}
</style> 