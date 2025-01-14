<template>
  <el-container>
    <el-header>
      <div class="header-content">
        <h1>VPS 价值追踪器</h1>
        <div class="header-right">
          <template v-if="authStore.isAuthenticated">
            <el-button type="danger" @click="handleLogout">退出登录</el-button>
          </template>
          <template v-else>
            <el-button type="primary" @click="$router.push('/login')">登录</el-button>
          </template>
        </div>
      </div>
    </el-header>
    <el-main>
      <router-view />
    </el-main>
  </el-container>
</template>

<script setup lang="ts">
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const handleLogout = () => {
  authStore.logout()
  router.push('/')
}
</script>

<style scoped>
.el-header {
  background-color: #fff;
  border-bottom: 1px solid #dcdfe6;
  padding: 0 20px;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.el-main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}
</style> 