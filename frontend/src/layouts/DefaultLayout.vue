<template>
  <el-container class="layout">
    <el-header>
      <div class="header-content">
        <h1>VPS Value Tracker</h1>
        <div class="header-right">
          <el-button v-if="token" type="primary" @click="router.push('/add')">
            添加 VPS
          </el-button>
          <el-button v-if="token" @click="logout">退出</el-button>
          <el-button v-else @click="router.push('/login')">登录</el-button>
        </div>
      </div>
    </el-header>

    <el-main>
      <router-view />
    </el-main>
  </el-container>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const token = ref(localStorage.getItem('token'))

const logout = () => {
  localStorage.removeItem('token')
  token.value = null
  router.push('/login')
}
</script>

<style scoped>
.layout {
  min-height: 100vh;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.header-right {
  display: flex;
  gap: 1rem;
}

h1 {
  margin: 0;
  font-size: 1.5rem;
}
</style> 