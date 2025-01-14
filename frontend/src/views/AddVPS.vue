<template>
  <div class="add-vps">
    <el-card>
      <template #header>
        <h2>添加 VPS</h2>
      </template>

      <el-form
        :model="form"
        label-position="top"
        @submit.prevent="handleSubmit"
      >
        <el-form-item label="服务商">
          <el-input v-model="form.provider" />
        </el-form-item>

        <el-form-item label="配置信息">
          <el-input
            v-model="form.specs"
            type="textarea"
            placeholder="例如：2核4G/80G SSD/1Gbps带宽"
          />
        </el-form-item>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="价格">
              <el-input-number v-model="form.price" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="货币">
              <el-select v-model="form.currency">
                <el-option label="CNY" value="CNY" />
                <el-option label="USD" value="USD" />
                <el-option label="EUR" value="EUR" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item>
          <el-button
            type="primary"
            :loading="loading"
            @click="handleSubmit"
          >
            添加
          </el-button>
          <el-button @click="router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { vpsApi, type VPS } from '@/utils/api'

const router = useRouter()
const loading = ref(false)

const form = ref<VPS>({
  provider: '',
  price: 0,
  currency: 'CNY',
  startDate: new Date().toISOString(),
  endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
  specs: ''
})

const handleSubmit = async () => {
  try {
    loading.value = true
    await vpsApi.create(form.value)
    ElMessage.success('添加成功')
    router.push('/')
  } catch (error) {
    ElMessage.error('添加失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.add-vps {
  max-width: 800px;
  margin: 20px auto;
}

h2 {
  margin: 0;
}
</style> 