// 配置
const CONFIG = {
    PASSWORD_KEY: 'admin_password',
    LOGIN_STATE_KEY: 'is_logged_in',
    STORAGE_KEY: 'vps_data'
};

// 汇率数据
let exchangeRates = null;

// 初始化
async function init() {
    await loadExchangeRates();
    setupEventListeners();
    initializeLoginState();
}

// 初始化登录状态
function initializeLoginState() {
    const savedPassword = localStorage.getItem(CONFIG.PASSWORD_KEY);
    const isLoggedIn = localStorage.getItem(CONFIG.LOGIN_STATE_KEY) === 'true';

    if (!savedPassword) {
        // 首次使用，显示密码设置界面
        handleFirstTimeSetup();
    } else if (isLoggedIn) {
        showLoggedInUI();
    } else {
        showLoggedOutUI();
    }
}

// 处理首次设置
function handleFirstTimeSetup() {
    const password = prompt('请设置管理密码（至少6位）：');
    if (!password) {
        showLoggedOutUI();
        return;
    }

    if (password.length < 6) {
        alert('密码长度不能少于6位！');
        handleFirstTimeSetup();
        return;
    }

    // 保存密码并登录
    localStorage.setItem(CONFIG.PASSWORD_KEY, password);
    localStorage.setItem(CONFIG.LOGIN_STATE_KEY, 'true');
    showLoggedInUI();
    initializeContent(); // 初始化内容
}

// 处理登录
function handleLogin() {
    const savedPassword = localStorage.getItem(CONFIG.PASSWORD_KEY);
    
    if (!savedPassword) {
        handleFirstTimeSetup();
        return;
    }

    const password = prompt('请输入管理密码：');
    if (!password) return;

    if (password === savedPassword) {
        localStorage.setItem(CONFIG.LOGIN_STATE_KEY, 'true');
        showLoggedInUI();
        initializeContent(); // 初始化内容
    } else {
        alert('密码错误！');
    }
}

// 处理登出
function handleLogout() {
    localStorage.removeItem(CONFIG.LOGIN_STATE_KEY);
    showLoggedOutUI();
}

// 显示已登录界面
function showLoggedInUI() {
    document.getElementById('loginBtn').style.display = 'none';
    document.getElementById('addVpsBtn').style.display = 'block';
    document.getElementById('exportBtn').style.display = 'block';
    document.getElementById('mainContent').style.display = 'block';
    renderVpsList();
}

// 显示未登录界面
function showLoggedOutUI() {
    document.getElementById('loginBtn').style.display = 'block';
    document.getElementById('addVpsBtn').style.display = 'none';
    document.getElementById('exportBtn').style.display = 'none';
    document.getElementById('mainContent').style.display = 'none';
}

// 初始化内容
function initializeContent() {
    // 确保主内容区域存在
    let mainContent = document.getElementById('mainContent');
    if (!mainContent) {
        mainContent = document.createElement('div');
        mainContent.id = 'mainContent';
        document.body.appendChild(mainContent);
    }
    renderVpsList();
}

// 设置事件监听器
function setupEventListeners() {
    document.getElementById('loginBtn').addEventListener('click', handleLogin);
    document.getElementById('addVpsBtn').addEventListener('click', showAddVpsForm);
    document.getElementById('exportBtn').addEventListener('click', exportToMarkdown);
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
    const modal = document.querySelector('.modal');
    if (modal) {
        modal.remove();
    }
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

// 显示添加VPS表单
function showAddVpsForm() {
    const mainContent = document.getElementById('mainContent');
    const formHtml = `
        <div class="modal">
            <div class="modal-content">
                <h2>添加 VPS</h2>
                <form id="vpsForm" onsubmit="handleAddVps(event)">
                    <div class="form-group">
                        <label>商家名称:</label>
                        <input type="text" name="provider" required>
                    </div>
                    <div class="form-group">
                        <label>CPU配置:</label>
                        <input type="number" name="cpuCores" placeholder="核心数" required>
                        <input type="text" name="cpuModel" placeholder="型号">
                    </div>
                    <div class="form-group">
                        <label>内存:</label>
                        <input type="number" name="ramSize" placeholder="GB" required>
                    </div>
                    <div class="form-group">
                        <label>硬盘:</label>
                        <input type="number" name="diskSize" placeholder="GB" required>
                    </div>
                    <div class="form-group">
                        <label>流量:</label>
                        <input type="number" name="bandwidth" required>
                        <select name="bandwidthUnit">
                            <option value="GB">GB</option>
                            <option value="TB">TB</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>价格:</label>
                        <input type="number" name="price" step="0.01" required>
                        <select name="currency">
                            <option value="CNY">CNY</option>
                            <option value="USD">USD</option>
                            <option value="EUR">EUR</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>购买日期:</label>
                        <input type="date" name="purchaseDate" required>
                    </div>
                    <div class="form-group">
                        <label>到期日期:</label>
                        <input type="date" name="expiryDate" required>
                    </div>
                    <div class="form-actions">
                        <button type="submit">保存</button>
                        <button type="button" onclick="closeAddVpsForm()">取消</button>
                    </div>
                </form>
            </div>
        </div>
    `;
    mainContent.insertAdjacentHTML('beforeend', formHtml);
}

// 处理添加VPS
function handleAddVps(event) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const vpsData = {
        provider: formData.get('provider'),
        cpuCores: parseInt(formData.get('cpuCores')),
        cpuModel: formData.get('cpuModel'),
        ramSize: parseInt(formData.get('ramSize')),
        diskSize: parseInt(formData.get('diskSize')),
        bandwidth: parseInt(formData.get('bandwidth')),
        bandwidthUnit: formData.get('bandwidthUnit'),
        price: parseFloat(formData.get('price')),
        currency: formData.get('currency'),
        purchaseDate: formData.get('purchaseDate'),
        expiryDate: formData.get('expiryDate'),
        addedDate: new Date().toISOString()
    };

    // 保存数据
    const existingData = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
    existingData.push(vpsData);
    localStorage.setItem(CONFIG.STORAGE_KEY, JSON.stringify(existingData));

    // 关闭表单并刷新列表
    closeAddVpsForm();
    renderVpsList();
}

// 导出数据为Markdown
function exportToMarkdown() {
    const vpsList = JSON.parse(localStorage.getItem(CONFIG.STORAGE_KEY) || '[]');
    if (vpsList.length === 0) {
        alert('没有数据可导出！');
        return;
    }

    let markdown = '# VPS列表\n\n';
    markdown += '| 商家 | CPU | 内存 | 硬盘 | 流量 | 价格 | 购买日期 | 到期日期 | 剩余价值 |\n';
    markdown += '|------|-----|------|------|------|------|----------|----------|----------|\n';

    vpsList.forEach(vps => {
        const remainingValue = calculateRemainingValue(vps);
        markdown += `| ${vps.provider} | ${vps.cpuCores}核 ${vps.cpuModel || ''} | ${vps.ramSize}GB | ${vps.diskSize}GB | ${vps.bandwidth}${vps.bandwidthUnit} | ${vps.price}${vps.currency} | ${vps.purchaseDate} | ${vps.expiryDate} | ${remainingValue.original.toFixed(2)}${vps.currency} |\n`;
    });

    // 创建下载链接
    const blob = new Blob([markdown], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `vps-list-${new Date().toISOString().split('T')[0]}.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
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