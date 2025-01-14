<template>
  <el-form
    ref="formRef"
    :model="form"
    :rules="rules"
    label-width="120px"
    class="vps-form"
  >
    <el-form-item label="商家名称" prop="merchantName">
      <el-input v-model="form.merchantName" />
    </el-form-item>

    <el-form-item label="CPU" required>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item prop="cpu.cores">
            <el-input-number
              v-model="form.cpu.cores"
              :min="1"
              label="核心数"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="cpu.model">
            <el-input
              v-model="form.cpu.model"
              placeholder="CPU型号"
            />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form-item>

    <el-form-item label="内存" required>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item prop="memory.size">
            <el-input-number
              v-model="form.memory.size"
              :min="1"
              :precision="0"
              label="内存大小"
            >
              <template #append>GB</template>
            </el-input-number>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="memory.type">
            <el-select v-model="form.memory.type" placeholder="内存类型">
              <el-option label="DDR3" value="DDR3" />
              <el-option label="DDR4" value="DDR4" />
              <el-option label="DDR5" value="DDR5" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
    </el-form-item>

    <el-form-item label="硬盘" required>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item prop="storage.size">
            <el-input-number
              v-model="form.storage.size"
              :min="1"
              :precision="0"
              label="硬盘大小"
            >
              <template #append>GB</template>
            </el-input-number>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="storage.type">
            <el-select v-model="form.storage.type" placeholder="硬盘类型">
              <el-option label="SSD" value="SSD" />
              <el-option label="NVMe" value="NVMe" />
              <el-option label="HDD" value="HDD" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
    </el-form-item>

    <el-form-item label="带宽" required>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item prop="bandwidth.size">
            <el-input-number
              v-model="form.bandwidth.size"
              :min="1"
              :precision="0"
              label="带宽大小"
            >
              <template #append>GB</template>
            </el-input-number>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="bandwidth.type">
            <el-select v-model="form.bandwidth.type" placeholder="带宽类型">
              <el-option label="共享" value="SHARED" />
              <el-option label="独享" value="DEDICATED" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
    </el-form-item>

    <el-form-item label="价格" required>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item prop="price.amount">
            <el-input-number
              v-model="form.price.amount"
              :precision="2"
              :min="0"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="price.currency">
            <el-select v-model="form.price.currency">
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
    </el-form-item>

    <el-form-item>
      <el-button 
        type="primary" 
        @click="submitForm"
      >
        {{ isEdit ? '保存修改' : '添加VPS' }}
      </el-button>
      <el-button @click="handleCancel">取消</el-button>
    </el-form-item>
  </el-form>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { vpsAPI } from '../api/vps';

const props = defineProps({
  initialData: {
    type: Object,
    default: null
  },
  isEdit: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['success', 'cancel']);

const formRef = ref();
const form = reactive({
  merchantName: '',
  cpu: {
    cores: 1,
    model: ''
  },
  memory: {
    size: 1,
    type: ''
  },
  storage: {
    size: 20,
    type: ''
  },
  bandwidth: {
    size: 1000,
    type: ''
  },
  price: {
    amount: 0,
    currency: 'CNY'
  }
});

const rules = {
  merchantName: [
    { required: true, message: '请输入商家名称', trigger: 'blur' }
  ],
  'cpu.cores': [
    { required: true, message: '请输入CPU核心数', trigger: 'blur' }
  ],
  'price.amount': [
    { required: true, message: '请输入价格', trigger: 'blur' }
  ],
  'price.currency': [
    { required: true, message: '请选择货币', trigger: 'change' }
  ],
  'memory.size': [
    { required: true, message: '请输入内存大小', trigger: 'blur' }
  ],
  'memory.type': [
    { required: true, message: '请选择内存类型', trigger: 'change' }
  ],
  'storage.size': [
    { required: true, message: '请输入硬盘大小', trigger: 'blur' }
  ],
  'storage.type': [
    { required: true, message: '请选择硬盘类型', trigger: 'change' }
  ],
  'bandwidth.size': [
    { required: true, message: '请输入带宽大小', trigger: 'blur' }
  ],
  'bandwidth.type': [
    { required: true, message: '请选择带宽类型', trigger: 'change' }
  ]
};

const convertToGB = (value, unit) => {
  switch (unit.toUpperCase()) {
    case 'TB':
      return value * 1024;
    case 'MB':
      return value / 1024;
    default:
      return value;
  }
};

onMounted(() => {
  if (props.initialData) {
    Object.keys(form).forEach(key => {
      if (typeof form[key] === 'object') {
        Object.assign(form[key], props.initialData[key]);
      } else {
        form[key] = props.initialData[key];
      }
    });
  }
});

const submitForm = async () => {
  if (!formRef.value) return;
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        const formData = {
          ...form,
          memory: {
            ...form.memory,
            size: convertToGB(form.memory.size, 'GB')
          },
          storage: {
            ...form.storage,
            size: convertToGB(form.storage.size, 'GB')
          },
          bandwidth: {
            ...form.bandwidth,
            size: convertToGB(form.bandwidth.size, 'GB')
          }
        };

        if (props.isEdit) {
          await vpsAPI.update(props.initialData._id, formData);
          ElMessage.success('修改成功');
        } else {
          await vpsAPI.create(formData);
          ElMessage.success('添加成功');
        }
        
        emit('success');
        if (!props.isEdit) {
          resetForm();
        }
      } catch (error) {
        ElMessage.error(props.isEdit ? '修改失败' : '添加失败');
      }
    }
  });
};

const handleCancel = () => {
  emit('cancel');
  if (!props.isEdit) {
    resetForm();
  }
};

const resetForm = () => {
  if (!formRef.value) return;
  formRef.value.resetFields();
};
</script>

<style scoped>
.vps-form {
  max-width: 800px;
  margin: 0 auto;
}

.el-input-number {
  width: 100%;
}

.el-select {
  width: 100%;
}
</style> 