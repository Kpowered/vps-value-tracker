// 配置
const CONFIG = {
    PASSWORD_KEY: 'admin_password',
    SESSION_KEY: 'login_session',
    FIXER_API_KEY: 'e65a0dbfc190ce964f2771bca5c08e13',
    STORAGE_KEY: 'vps_data'
};

// 汇率数据
let exchangeRates = null;

// 初始化
async function init() {
    await loadExchangeRates();
    
    // 检查登录状态
    checkLoginStatus();
    renderVpsList();
}

// 检查登录状态
function checkLoginStatus() {
    const savedPassword = localStorage.getItem(CONFIG.PASSWORD_KEY);
    const sessionToken = sessionStorage.getItem(CONFIG.SESSION_KEY);
    
    if (savedPassword && sessionToken) {
        // 已登录状态
        showLoggedInUI();
    } else {
        // 未登录状态
        showLoggedOutUI();
    }
}

// 显示已登录UI
function showLoggedInUI() {
    document.getElementById('loginBtn').style.display = 'none';
    document.getElementById('addVpsBtn').style.display = 'block';
    document.getElementById('exportBtn').style.display = 'block';
}

// 显示未登录UI
function showLoggedOutUI() {
    document.getElementById('loginBtn').style.display = 'block';
    document.getElementById('addVpsBtn').style.display = 'none';
    document.getElementById('exportBtn').style.display = 'none';
}

// 登录处理
function handleLogin() {
    const password = prompt('请输入管理密码（至少6位）：');
    if (!password) return;
    
    if (password.length < 6) {
        alert('密码长度不能少于6位！');
        return;
    }
    
    const savedPassword = localStorage.getItem(CONFIG.PASSWORD_KEY);
    if (!savedPassword) {
        // 首次设置密码
        localStorage.setItem(CONFIG.PASSWORD_KEY, password);
        sessionStorage.setItem(CONFIG.SESSION_KEY, 'logged_in');
        showLoggedInUI();
    } else if (password === savedPassword) {
        // 密码正确
        sessionStorage.setItem(CONFIG.SESSION_KEY, 'logged_in');
        showLoggedInUI();
    } else {
        // 密码错误
        alert('密码错误！');
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
    
    // 创建表格视图
    vpsList.innerHTML = `
        <div class="vps-table-container">
            <table class="vps-table">
                <thead>
                    <tr>
                        <th>商家</th>
                        <th>CPU</th>
                        <th>内存</th>
                        <th>硬盘</th>
                        <th>流量</th>
                        <th>价格</th>
                        <th>购买日期</th>
                        <th>到期时间</th>
                        <th>剩余价值</th>
                        <th>剩余天数</th>
                        ${isAdmin ? '<th>操作</th>' : ''}
                    </tr>
                </thead>
                <tbody>
                    ${vpsData.map((vps, index) => {
                        const remainingValue = calculateRemainingValue(vps);
                        return `
                            <tr>
                                <td>${vps.provider}</td>
                                <td>${vps.cpuCores}核 ${vps.cpuModel || '未指定'}</td>
                                <td>${vps.ramSize}GB ${vps.ramModel ? `(${vps.ramModel})` : ''}</td>
                                <td>${vps.diskSize}GB ${vps.diskModel ? `(${vps.diskModel})` : ''}</td>
                                <td>${vps.bandwidth}${vps.bandwidthUnit}</td>
                                <td>${vps.price} ${vps.currency}</td>
                                <td>${new Date(vps.purchaseDate).toLocaleDateString('zh-CN')}</td>
                                <td>${new Date(vps.expiryDate).toLocaleDateString('zh-CN')}</td>
                                <td class="remaining-value">
                                    ${remainingValue.original.toFixed(2)} ${vps.currency}<br>
                                    <span class="cny-value">(￥${remainingValue.cny.toFixed(2)})</span>
                                </td>
                                <td>${remainingValue.remainingDays}/${remainingValue.totalDays}</td>
                                ${isAdmin ? `
                                    <td>
                                        <button class="delete-btn-small" onclick="deleteVps(${index})" title="删除">×</button>
                                    </td>
                                ` : ''}
                            </tr>
                        `;
                    }).join('')}
                </tbody>
            </table>
        </div>
    `;
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

// 添加删除VPS函数
function deleteVps(index) {
    if (confirm('确定要删除这个VPS吗？此操作不可撤销。')) {
        const vpsData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
        vpsData.splice(index, 1);
        localStorage.setItem(CONFIG.STORAGE_KEY, JSON.stringify(vpsData));
        renderVpsList();
    }
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

// 启动应用
init(); 