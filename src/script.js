// 配置
const CONFIG = {
    PASSWORD_KEY: 'admin_password',
    FIXER_API_KEY: 'e65a0dbfc190ce964f2771bca5c08e13',
    STORAGE_KEY: 'vps_data'
};

// 汇率数据
let exchangeRates = null;

// 初始化
async function init() {
    await loadExchangeRates();
    renderVpsList();
    setupEventListeners();
    
    // 检查是否需要设置初始密码
    if (!isPasswordSet()) {
        showSetPasswordForm();
    }
}

// 加载汇率数据
async function loadExchangeRates() {
    const cachedRates = localStorage.getItem('exchange_rates');
    const cacheTime = localStorage.getItem('exchange_rates_time');
    
    // 如果缓存的汇率数据不超过24小时，直接使用缓存
    if (cachedRates && cacheTime && (Date.now() - parseInt(cacheTime)) < 24 * 60 * 60 * 1000) {
        exchangeRates = JSON.parse(cachedRates);
        return;
    }

    try {
        const response = await fetch(`https://data.fixer.io/api/latest?access_key=${CONFIG.FIXER_API_KEY}&base=EUR`);
        const data = await response.json();
        
        if (data.success) {
            exchangeRates = data.rates;
            localStorage.setItem('exchange_rates', JSON.stringify(exchangeRates));
            localStorage.setItem('exchange_rates_time', Date.now().toString());
        }
    } catch (error) {
        console.error('Failed to load exchange rates:', error);
        // 如果有缓存数据，使用缓存
        if (cachedRates) {
            exchangeRates = JSON.parse(cachedRates);
        }
    }
}

// 转换货币到人民币
function convertToCNY(amount, fromCurrency) {
    if (!exchangeRates) return amount;
    if (fromCurrency === 'CNY') return amount;
    
    const eurAmount = fromCurrency === 'EUR' ? amount : amount / exchangeRates[fromCurrency];
    return eurAmount * exchangeRates['CNY'];
}

// 计算剩余价值
function calculateRemainingValue(vps) {
    const now = new Date();
    const expiry = new Date(vps.expiryDate);
    const purchase = new Date(vps.purchaseDate);
    
    // 计算总天数（从购买日到到期日）
    const totalDays = Math.ceil((expiry - purchase) / (1000 * 60 * 60 * 24));
    // 计算剩余天数
    const remainingDays = Math.max(0, Math.ceil((expiry - now) / (1000 * 60 * 60 * 24)));
    // 计算剩余价值（考虑实际合同期限）
    const remainingValue = (vps.price * remainingDays) / totalDays;
    
    return {
        original: remainingValue,
        cny: convertToCNY(remainingValue, vps.currency),
        remainingDays: remainingDays,
        totalDays: totalDays
    };
}

// 渲染VPS列表
function renderVpsList() {
    const vpsList = document.getElementById('vpsList');
    const vpsData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
    const isAdmin = document.getElementById('adminPanel').classList.contains('hidden') === false;
    
    vpsList.innerHTML = vpsData.map((vps, index) => {
        const remainingValue = calculateRemainingValue(vps);
        return `
            <div class="vps-card">
                ${isAdmin ? `
                    <button class="delete-btn" onclick="deleteVps(${index})" title="删除">
                        ×
                    </button>
                ` : ''}
                <h3>${vps.provider}</h3>
                <div class="vps-info">
                    <p>CPU: ${vps.cpuCores}核 ${vps.cpuModel || '未指定'}</p>
                    <p>内存: ${vps.ramSize}GB ${vps.ramModel ? `(${vps.ramModel})` : ''}</p>
                    <p>硬盘: ${vps.diskSize}GB ${vps.diskModel ? `(${vps.diskModel})` : ''}</p>
                    <p>流量: ${vps.bandwidth}${vps.bandwidthUnit}</p>
                    <p>价格: ${vps.price} ${vps.currency}</p>
                    <p>购买日期: ${new Date(vps.purchaseDate).toLocaleDateString('zh-CN')}</p>
                    <p>到期时间: ${new Date(vps.expiryDate).toLocaleDateString('zh-CN')}</p>
                    <div class="remaining-value">
                        剩余价值: ${remainingValue.original.toFixed(2)} ${vps.currency}
                        (￥${remainingValue.cny.toFixed(2)})
                        <div class="remaining-days">
                            剩余天数: ${remainingValue.remainingDays}天 / 总天数: ${remainingValue.totalDays}天
                        </div>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

// 设置事件监听器
function setupEventListeners() {
    // 登录按钮
    document.getElementById('loginBtn').addEventListener('click', () => {
        document.getElementById('loginForm').classList.remove('hidden');
    });

    // 添加VPS按钮
    document.getElementById('addVpsBtn')?.addEventListener('click', () => {
        document.getElementById('addVpsForm').classList.remove('hidden');
        
        // 设置默认日期
        const today = new Date();
        const nextYear = new Date();
        nextYear.setFullYear(today.getFullYear() + 1);
        
        document.querySelector('input[name="purchaseDate"]').value = 
            today.toISOString().split('T')[0];
        document.querySelector('input[name="expiryDate"]').value = 
            nextYear.toISOString().split('T')[0];
    });

    // VPS表单提交
    document.getElementById('vpsForm')?.addEventListener('submit', (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const vpsData = {
            provider: formData.get('provider'),
            cpuCores: parseInt(formData.get('cpuCores')),
            cpuModel: formData.get('cpuModel'),
            ramSize: parseInt(formData.get('ramSize')),
            ramModel: formData.get('ramModel'),
            diskSize: parseInt(formData.get('diskSize')),
            diskModel: formData.get('diskModel'),
            bandwidth: parseInt(formData.get('bandwidth')),
            bandwidthUnit: formData.get('bandwidthUnit'),
            price: parseFloat(formData.get('price')),
            currency: formData.get('currency'),
            purchaseDate: formData.get('purchaseDate'),
            expiryDate: formData.get('expiryDate'),
            addedDate: new Date().toISOString()
        };

        const existingData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
        existingData.push(vpsData);
        localStorage.setItem(CONFIG.STORAGE_KEY, JSON.stringify(existingData));

        closeAddVpsForm();
        renderVpsList();
    });
}

// 登录功能
function login() {
    const password = document.getElementById('password').value;
    const storedPassword = localStorage.getItem(CONFIG.PASSWORD_KEY);
    
    if (password === storedPassword) {
        document.getElementById('loginForm').classList.add('hidden');
        document.getElementById('adminPanel').classList.remove('hidden');
        document.getElementById('loginBtn').classList.add('hidden');
    } else {
        alert('密码错误！');
    }
}

// 关闭添加VPS表单
function closeAddVpsForm() {
    document.getElementById('addVpsForm').classList.add('hidden');
    document.getElementById('vpsForm').reset();
}

// 添加密码检查函数
function isPasswordSet() {
    return localStorage.getItem(CONFIG.PASSWORD_KEY) !== null;
}

// 添加密码设置表单函数
function showSetPasswordForm() {
    const loginForm = document.getElementById('loginForm');
    loginForm.classList.remove('hidden');
    loginForm.innerHTML = `
        <div class="modal-content">
            <h2>设置管理密码</h2>
            <div class="form-group">
                <input type="password" id="newPassword" placeholder="请输入密码" required>
                <input type="password" id="confirmPassword" placeholder="请确认密码" required>
            </div>
            <button onclick="setInitialPassword()">确认</button>
        </div>
    `;
}

// 添加密码设置函数
function setInitialPassword() {
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    
    if (!newPassword || newPassword.length < 6) {
        alert('密码长度至少需要6位！');
        return;
    }
    
    if (newPassword !== confirmPassword) {
        alert('两次输入的密码不一致！');
        return;
    }
    
    localStorage.setItem(CONFIG.PASSWORD_KEY, newPassword);
    document.getElementById('loginForm').classList.add('hidden');
    alert('密码设置成功！');
}

// 添加删除VPS函数
function deleteVps(index) {
    if (confirm('确定要删除这个VPS吗？此操作不可撤销。')) {
        const vpsData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
        vpsData.splice(index, 1);
        localStorage.setItem(CONFIG.STORAGE_KEY, JSON.stringify(vpsData));
        renderVpsList();
    }
}

// 启动应用
init(); 