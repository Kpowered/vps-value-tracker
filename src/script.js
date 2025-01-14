// 配置
const CONFIG = {
    PASSWORD_KEY: 'admin_password',
    FIXER_API_KEY: 'e65a0dbfc190ce964f2771bca5c08e13',
    STORAGE_KEY: 'vps_data'
};

// 汇率数据
let exchangeRates = null;

// 添加IndexedDB支持，提供更可靠的本地存储
const dbName = 'vpsTracker';
const dbVersion = 1;

// 初始化
async function init() {
    await loadExchangeRates();
    renderVpsList();
    setupEventListeners();
    addExportButton();
    
    // 检查是否需要设置初始密码
    if (!isPasswordSet()) {
        showSetPasswordForm();
    } else {
        // 确保登录表单处于正确状态
        resetLoginForm();
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

    // 添加备用API
    try {
        const response = await fetch('https://alternate-api.example.com/rates');
        // 处理备用API响应...
    } catch (backupError) {
        console.error('All API attempts failed:', backupError);
        // 使用硬编码的备用汇率
        return {
            EUR: 1,
            USD: 1.1,
            CNY: 7.8,
            // ... 其他货币
        };
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
function renderVpsList(page = 1, pageSize = 10) {
    const vpsData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
    const start = (page - 1) * pageSize;
    const end = start + pageSize;
    const pageData = vpsData.slice(start, end);
    
    // 渲染逻辑...
}

// 设置事件监听器
function setupEventListeners() {
    // 登录按钮
    document.getElementById('loginBtn').addEventListener('click', () => {
        if (!isPasswordSet()) {
            showSetPasswordForm();
        } else {
            resetLoginForm();
            document.getElementById('loginForm').classList.remove('hidden');
        }
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
    
    // 更新登录表单状态
    resetLoginForm();
    
    alert('密码设置成功！');
}

// 添加重置登录表单函数
function resetLoginForm() {
    const loginForm = document.getElementById('loginForm');
    loginForm.innerHTML = `
        <div class="modal-content">
            <button type="button" class="modal-close" onclick="closeLoginForm()">×</button>
            <h2>登录</h2>
            <div class="form-group">
                <input type="password" id="password" placeholder="请输入密码">
            </div>
            <div class="form-actions">
                <button class="btn btn-primary" onclick="login()">确认</button>
            </div>
        </div>
    `;
}

// 添加关闭登录表单函数
function closeLoginForm() {
    document.getElementById('loginForm').classList.add('hidden');
}

// 修改删除VPS函数
function deleteVps(index) {
    const modal = document.createElement('div');
    modal.className = 'modal confirm-modal';
    modal.innerHTML = `
        <div class="modal-content">
            <h2>确认删除</h2>
            <p>确定要删除这个VPS吗？此操作不可撤销。</p>
            <div class="btn-group">
                <button class="btn btn-danger" onclick="confirmDelete(${index}, this)">确认删除</button>
                <button class="btn btn-secondary" onclick="this.closest('.modal').remove()">取消</button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

// 添加确认删除函数
function confirmDelete(index, button) {
    const vpsData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
    vpsData.splice(index, 1);
    localStorage.setItem(CONFIG.STORAGE_KEY, JSON.stringify(vpsData));
    renderVpsList();
    button.closest('.modal').remove();
}

// 添加导出为 Markdown 表格的函数
function exportToMarkdown() {
    const vpsData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
    
    // 表格头部
    let markdown = `| 商家 | CPU | 内存 | 硬盘 | 流量 | 价格 | 购买日期 | 到期时间 | 剩余价值 | 剩余天数 |\n`;
    markdown += `|------|-----|------|------|------|------|----------|----------|----------|----------|\n`;
    
    // 表格内容
    vpsData.forEach(vps => {
        const remainingValue = calculateRemainingValue(vps);
        markdown += `| ${vps.provider} | ${vps.cpuCores}核 ${vps.cpuModel || '未指定'} | ${vps.ramSize}GB ${vps.ramModel || ''} | ${vps.diskSize}GB ${vps.diskModel || ''} | ${vps.bandwidth}${vps.bandwidthUnit} | ${vps.price} ${vps.currency} | ${new Date(vps.purchaseDate).toLocaleDateString('zh-CN')} | ${new Date(vps.expiryDate).toLocaleDateString('zh-CN')} | ${remainingValue.original.toFixed(2)} ${vps.currency} (￥${remainingValue.cny.toFixed(2)}) | ${remainingValue.remainingDays}/${remainingValue.totalDays} |\n`;
    });
    
    return markdown;
}

// 添加导出按钮到页面
function addExportButton() {
    const header = document.querySelector('header');
    const exportBtn = document.createElement('button');
    exportBtn.className = 'btn btn-secondary';
    exportBtn.style.marginLeft = '10px';
    exportBtn.textContent = '导出表格';
    exportBtn.onclick = () => {
        const markdown = exportToMarkdown();
        
        // 创建一个模态框来显示 Markdown
        const modal = document.createElement('div');
        modal.className = 'modal';
        modal.innerHTML = `
            <div class="modal-content">
                <button type="button" class="modal-close" onclick="this.parentElement.parentElement.remove()">×</button>
                <h2>Markdown 表格</h2>
                <div class="markdown-container">
                    <pre>${markdown}</pre>
                </div>
                <div class="form-actions">
                    <button class="btn btn-primary" onclick="copyToClipboard(this)">复制到剪贴板</button>
                    <button class="btn btn-secondary" onclick="downloadMarkdown()">下载文件</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
    };
    header.appendChild(exportBtn);
}

// 复制到剪贴板功能
function copyToClipboard(button) {
    const pre = button.parentElement.previousElementSibling.querySelector('pre');
    const text = pre.textContent;
    
    // 创建临时文本区域
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    
    try {
        // 选择文本
        textarea.select();
        textarea.setSelectionRange(0, 99999); // 对于移动设备
        
        // 执行复制命令
        document.execCommand('copy');
        
        // 提示成功
        const originalText = button.textContent;
        button.textContent = '已复制！';
        setTimeout(() => {
            button.textContent = originalText;
        }, 2000);
    } catch (err) {
        console.error('复制失败:', err);
        alert('复制失败，请手动复制');
    } finally {
        // 清理临时元素
        document.body.removeChild(textarea);
    }
}

// 添加下载功能
function downloadMarkdown() {
    const markdown = exportToMarkdown();
    const blob = new Blob([markdown], { type: 'text/markdown' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `vps-list-${new Date().toISOString().split('T')[0]}.md`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
}

// 建议添加数据备份/恢复功能
function exportData() {
    const data = {
        vps_list: JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]'),
        timestamp: new Date().toISOString()
    };
    return JSON.stringify(data);
}

function importData(jsonString) {
    try {
        const data = JSON.parse(jsonString);
        localStorage.setItem(CONFIG.STORAGE_KEY, JSON.stringify(data.vps_list));
        return true;
    } catch (e) {
        console.error('Import failed:', e);
        return false;
    }
}

// 建议添加密码强度检查
function validatePassword(password) {
    const minLength = 8;
    const hasNumber = /\d/.test(password);
    const hasLetter = /[a-zA-Z]/.test(password);
    const hasSpecial = /[!@#$%^&*]/.test(password);
    
    return password.length >= minLength && hasNumber && hasLetter && hasSpecial;
}

// 建议添加数据导出/导入功能，避免localStorage数据丢失
function backupData() {
    const data = localStorage.getItem(CONFIG.STORAGE_KEY);
    // 添加数据导出功能
}

function restoreData(backupFile) {
    // 添加数据恢复功能
}

// 启动应用
init(); 

async function initDB() {
    // 初始化IndexedDB
} 