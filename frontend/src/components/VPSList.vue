<template>
  <div class="vps-list">
    <div v-for="vps in vpsList" :key="vps.id" class="vps-card">
      <h3>{{ vps.vendor }}</h3>
      <div class="specs">
        <p>CPU: {{ vps.cpu_cores }}核 {{ vps.cpu_model }}</p>
        <p>内存: {{ vps.memory_gb }}GB</p>
        <p>硬盘: {{ vps.disk_gb }}GB</p>
        <p>流量: {{ vps.bandwidth_gb }}GB</p>
      </div>
      <div class="value">
        <p>原价: {{ vps.price }} {{ vps.currency }}</p>
        <p>剩余价值: {{ vps.remaining_value }} {{ vps.currency }}</p>
        <p>约合人民币: ¥{{ vps.remaining_value_cny }}</p>
      </div>
    </div>
  </div>
</template> 