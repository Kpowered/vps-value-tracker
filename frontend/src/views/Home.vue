<template>
  <div class="home">
    <el-container>
      <!-- 响应式头部 -->
      <el-header>
        <div class="header-content">
          <div class="header-left">
            <h1 class="title">VPS 价值追踪器</h1>
          </div>
          <div class="header-right">
            <div v-if="isLoggedIn" class="auth-buttons">
              <el-button 
                @click="showAddVPS"
                :icon="Plus"
                class="add-button"
              >
                <span class="button-text">添加VPS</span>
              </el-button>
              <el-button 
                type="text" 
                @click="logout"
                class="logout-button"
              >
                退出登录
              </el-button>
            </div>
            <el-button 
              v-else 
              type="primary" 
              @click="$router.push('/login')"
            >
              登录
            </el-button>
          </div>
        </div>
      </el-header>

      <el-main>
        <div class="content-container">
          <RateDisplay />
          <VPSList />
        </div>

        <el-dialog
          v-model="dialogVisible"
          title="添加VPS"
          :width="dialogWidth"
          :fullscreen="isMobile"
        >
          <VPSForm @success="handleAddSuccess" />
        </el-dialog>
      </el-main>
    </el-container>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useStore } from 'vuex';
import { Plus } from '@element-plus/icons-vue';
import VPSList from '../components/VPSList.vue';
import VPSForm from '../components/VPSForm.vue';
import RateDisplay from '../components/RateDisplay.vue';

const store = useStore();
const dialogVisible = ref(false);
const windowWidth = ref(window.innerWidth);
const isLoggedIn = computed(() => store.state.isLoggedIn);

// 响应式对话框宽度
const dialogWidth = computed(() => {
  if (windowWidth.value < 768) return '95%';
  if (windowWidth.value < 1200) return '80%';
  return '50%';
});

// 是否为移动设备
const isMobile = computed(() => windowWidth.value < 768);

// 监听窗口大小变化
const handleResize = () => {
  windowWidth.value = window.innerWidth;
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

const showAddVPS = () => {
  dialogVisible.value = true;
};

const handleAddSuccess = () => {
  dialogVisible.value = false;
};

const logout = () => {
  store.dispatch('logout');
};
</script>

<style scoped>
.home {
  min-height: 100vh;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  height: 100%;
}

.title {
  margin: 0;
  font-size: 1.5rem;
}

.content-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 20px;
}

.el-header {
  background-color: #fff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.12);
  position: sticky;
  top: 0;
  z-index: 100;
}

.auth-buttons {
  display: flex;
  gap: 10px;
  align-items: center;
}

/* 响应式样式 */
@media (max-width: 768px) {
  .header-content {
    padding: 0 10px;
  }

  .title {
    font-size: 1.2rem;
  }

  .button-text {
    display: none;
  }

  .content-container {
    padding: 0 10px;
  }

  .auth-buttons {
    gap: 5px;
  }

  .logout-button {
    padding: 0 5px;
  }
}

@media (max-width: 480px) {
  .el-header {
    padding: 0 5px;
  }

  .title {
    font-size: 1rem;
  }
}
</style> 