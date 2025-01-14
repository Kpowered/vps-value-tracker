<template>
  <div class="vps-list">
    <!-- 移动端视图 -->
    <div v-if="isMobile" class="mobile-list">
      <el-card v-for="vps in vpsList" :key="vps._id" class="vps-card">
        <template #header>
          <div class="card-header">
            <span>{{ vps.merchantName }}</span>
            <div v-if="isLoggedIn" class="card-actions">
              <el-button type="primary" size="small" @click="handleEdit(vps)">
                编辑
              </el-button>
              <el-button type="danger" size="small" @click="handleDelete(vps)">
                删除
              </el-button>
            </div>
          </div>
        </template>
        
        <div class="vps-info">
          <div class="info-item">
            <label>配置信息：</label>
            <div>CPU: {{ vps.cpu.cores }}核 {{ vps.cpu.model }}</div>
            <div>内存: {{ vps.memory.size }}GB {{ vps.memory.type }}</div>
            <div>硬盘: {{ vps.storage.size }}GB {{ vps.storage.type }}</div>
            <div>带宽: {{ vps.bandwidth.size }}GB {{ vps.bandwidth.type }}</div>
          </div>
          
          <div class="info-item">
            <label>价格：</label>
            <div>
              {{ vps.price.amount }} {{ vps.price.currency }}
              <el-tag size="small">≈ ¥{{ vps.price.cnyAmount.toFixed(2) }}</el-tag>
            </div>
          </div>
          
          <div class="info-item">
            <label>剩余价值：</label>
            <div>
              {{ vps.remainingValue.original.amount.toFixed(2) }}
              {{ vps.remainingValue.original.currency }}
              <el-tag type="success" size="small">
                ≈ ¥{{ vps.remainingValue.cny.toFixed(2) }}
              </el-tag>
            </div>
          </div>
          
          <div class="info-item">
            <label>到期时间：</label>
            <div>{{ new Date(vps.endDate).toLocaleDateString() }}</div>
          </div>
        </div>
      </el-card>
    </div>

    <!-- 桌面端视图 -->
    <el-table
      v-else
      :data="vpsList"
      style="width: 100%"
      :default-sort="{ prop: 'remainingValue.cny', order: 'descending' }"
    >
      <el-table-column prop="merchantName" label="商家名称" />
      <el-table-column label="配置信息">
        <template #default="{ row }">
          <div>CPU: {{ row.cpu.cores }}核 {{ row.cpu.model }}</div>
          <div>内存: {{ row.memory.size }}GB {{ row.memory.type }}</div>
          <div>硬盘: {{ row.storage.size }}GB {{ row.storage.type }}</div>
          <div>带宽: {{ row.bandwidth.size }}GB {{ row.bandwidth.type }}</div>
        </template>
      </el-table-column>
      <el-table-column label="价格">
        <template #default="{ row }">
          <div>
            {{ row.price.amount }} {{ row.price.currency }}
            <el-tag size="small">≈ ¥{{ row.price.cnyAmount.toFixed(2) }}</el-tag>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="剩余价值">
        <template #default="{ row }">
          <div>
            {{ row.remainingValue.original.amount.toFixed(2) }} 
            {{ row.remainingValue.original.currency }}
            <el-tag type="success" size="small">
              ≈ ¥{{ row.remainingValue.cny.toFixed(2) }}
            </el-tag>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="到期时间">
        <template #default="{ row }">
          {{ new Date(row.endDate).toLocaleDateString() }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button
            v-if="isLoggedIn"
            type="primary"
            size="small"
            @click="handleEdit(row)"
          >
            编辑
          </el-button>
          <el-button
            v-if="isLoggedIn"
            type="danger"
            size="small"
            @click="handleDelete(row)"
          >
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 编辑对话框 -->
    <el-dialog
      v-model="editDialogVisible"
      title="编辑VPS"
      :width="dialogWidth"
      :fullscreen="isMobile"
    >
      <VPSForm
        v-if="editDialogVisible"
        :initial-data="currentVPS"
        :is-edit="true"
        @success="handleEditSuccess"
        @cancel="editDialogVisible = false"
      />
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useStore } from 'vuex';
import { ElMessageBox } from 'element-plus';
import { vpsAPI } from '../api/vps';
import VPSForm from './VPSForm.vue';

const store = useStore();
const vpsList = ref([]);
const editDialogVisible = ref(false);
const currentVPS = ref(null);
const isLoggedIn = computed(() => store.state.isLoggedIn);

const windowWidth = ref(window.innerWidth);
const isMobile = computed(() => windowWidth.value < 768);
const dialogWidth = computed(() => isMobile.value ? '95%' : '50%');

const handleResize = () => {
  windowWidth.value = window.innerWidth;
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

const loadVPSList = async () => {
  try {
    vpsList.value = await vpsAPI.getAll();
  } catch (error) {
    ElMessage.error('加载VPS列表失败');
  }
};

const handleEdit = (row) => {
  currentVPS.value = { ...row };
  editDialogVisible.value = true;
};

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      '确定要删除这个VPS记录吗？',
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    );

    await vpsAPI.delete(row._id);
    ElMessage.success('删除成功');
    loadVPSList();
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败');
    }
  }
};

const handleEditSuccess = () => {
  editDialogVisible.value = false;
  loadVPSList();
};

onMounted(loadVPSList);
</script>

<style scoped>
.vps-list {
  width: 100%;
}

.mobile-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.vps-card {
  margin-bottom: 10px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-actions {
  display: flex;
  gap: 8px;
}

.vps-info {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.info-item {
  border-bottom: 1px solid var(--border-color);
  padding-bottom: 10px;
}

.info-item:last-child {
  border-bottom: none;
}

.info-item label {
  font-weight: 500;
  color: var(--text-color);
  margin-bottom: 5px;
  display: block;
}

@media (max-width: 768px) {
  .el-table {
    display: none;
  }
}

@media (min-width: 769px) {
  .mobile-list {
    display: none;
  }
}
</style> 