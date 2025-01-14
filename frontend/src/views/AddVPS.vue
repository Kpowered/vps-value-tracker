<template>
  <div class="add-vps">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>添加 VPS</span>
        </div>
      </template>

      <el-form ref="formRef" :model="form" :rules="rules" label-width="120px">
        <!-- 基本信息 -->
        <el-form-item label="服务商" prop="provider">
          <el-input v-model="form.provider" placeholder="请输入服务商名称" />
        </el-form-item>

        <!-- 价格信息 -->
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="价格" prop="price">
              <el-input-number v-model="form.price" :min="0" :precision="2" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="货币" prop="currency">
              <el-select v-model="form.currency">
                <el-option label="人民币" value="CNY" />
                <el-option label="美元" value="USD" />
                <el-option label="欧元" value="EUR" />
                <el-option label="英镑" value="GBP" />
                <el-option label="加元" value="CAD" />
                <el-option label="日元" value="JPY" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <!-- CPU配置 -->
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="CPU核心数" prop="cpu.cores">
              <el-input-number v-model="form.cpu.cores" :min="1" :max="128" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="CPU型号" prop="cpu.model">
              <el-input v-model="form.cpu.model" placeholder="例如: Intel Xeon E5-2680" />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 内存配置 -->
        <el-form-item label="内存大小(GB)" prop="memory.size">
          <el-input-number v-model="form.memory.size" :min="0.5" :max="1024" :step="0.5" />
        </el-form-item>

        <!-- 存储配置 -->
        <el-form-item label="硬盘大小(GB)" prop="storage.size">
          <el-input-number v-model="form.storage.size" :min="1" :max="10000" />
        </el-form-item>

        <!-- 带宽配置 -->
        <el-form-item label="月流量(GB)" prop="bandwidth.amount">
          <el-input-number v-model="form.bandwidth.amount" :min="1" :max="100000" />
        </el-form-item>

        <!-- 时间配置 -->
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="开始时间" prop="startDate">
              <el-date-picker
                v-model="form.startDate"
                type="date"
                placeholder="选择开始时间"
                :disabled="true"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="到期时间" prop="endDate">
              <el-date-picker
                v-model="form.endDate"
                type="date"
                placeholder="选择到期时间"
                :disabled="true"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 提交按钮 -->
        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="loading">保存</el-button>
          <el-button @click="$router.push('/')">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance } from 'element-plus'
import { api } from '../utils/api'

const router = useRouter()
const formRef = ref<FormInstance>()
const loading = ref(false)

const form = reactive({
  provider: '',
  price: 0,
  currency: 'CNY',
  startDate: new Date(),
  endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 一年后
  cpu: {
    cores: 1,
    model: ''
  },
  memory: {
    size: 1,
    type: 'DDR4'
  },
  storage: {
    size: 20,
    type: 'SSD'
  },
  bandwidth: {
    amount: 1000,
    type: 'Monthly'
  }
})

const rules = {
  provider: [{ required: true, message: '请输入服务商名称', trigger: 'blur' }],
  price: [{ required: true, message: '请输入价格', trigger: 'blur' }],
  currency: [{ required: true, message: '请选择货币', trigger: 'change' }],
  'cpu.cores': [{ required: true, message: '请输入CPU核心数', trigger: 'blur' }],
  'cpu.model': [{ required: true, message: '请输入CPU型号', trigger: 'blur' }],
  'memory.size': [{ required: true, message: '请输入内存大小', trigger: 'blur' }],
  'storage.size': [{ required: true, message: '请输入硬盘大小', trigger: 'blur' }],
  'bandwidth.amount': [{ required: true, message: '请输入流量大小', trigger: 'blur' }]
}

const handleSubmit = async () => {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        await api.post('/vps', form)
        ElMessage.success('添加成功')
        router.push('/')
      } catch (error) {
        console.error('Failed to add VPS:', error)
      } finally {
        loading.value = false
      }
    }
  })
}
</script>

<style scoped>
.add-vps {
  max-width: 800px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style> 