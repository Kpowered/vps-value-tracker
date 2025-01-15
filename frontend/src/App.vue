<template>
  <div class="app">
    <header>
      <h1>VPS 价值追踪器</h1>
    </header>
    <main>
      <VPSForm />
      <VPSList />
    </main>
  </div>
</template>

<script setup lang="ts">
import VPSForm from './components/VPSForm.vue'
import VPSList from './components/VPSList.vue'
</script>

<style>
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
    Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  background-color: #f5f5f5;
}

.app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

header {
  text-align: center;
  margin-bottom: 2rem;
}

h1 {
  color: #2c3e50;
}
</style> 