<template>
  <div class="vps-form">
    <form @submit.prevent="submitVPS">
      <input v-model="vps.vendor" placeholder="商家名称" required>
      
      <div class="cpu-input">
        <input v-model.number="vps.cpu_cores" type="number" placeholder="CPU核心数" required>
        <input v-model="vps.cpu_model" placeholder="CPU型号" required>
      </div>

      <input v-model.number="vps.memory_gb" type="number" placeholder="内存(GB)" required>
      <input v-model.number="vps.disk_gb" type="number" placeholder="硬盘(GB)" required>
      <input v-model.number="vps.bandwidth_gb" type="number" placeholder="流量(GB)" required>
      
      <div class="price-input">
        <input v-model.number="vps.price" type="number" step="0.01" placeholder="价格" required>
        <select v-model="vps.currency">
          <option value="CNY">人民币</option>
          <option value="USD">美元</option>
          <option value="EUR">欧元</option>
          <option value="GBP">英镑</option>
          <option value="CAD">加元</option>
          <option value="JPY">日元</option>
        </select>
      </div>

      <button type="submit">添加VPS</button>
    </form>
  </div>
</template> 