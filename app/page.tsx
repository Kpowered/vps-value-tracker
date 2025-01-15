'use client'

import { useEffect, useState } from 'react'
import { formatDistanceToNow } from 'date-fns'
import { zhCN } from 'date-fns/locale'

interface Vps {
  id: number
  name: string
  cpu: string
  memory: number
  disk: number
  bandwidth: number
  price: number
  currency: string
  endTime: string
}

export default function Home() {
  const [vpsList, setVpsList] = useState<Vps[]>([])
  const [isAdding, setIsAdding] = useState(false)
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [loginForm, setLoginForm] = useState({ username: '', password: '' })
  const [rates, setRates] = useState<Record<string, number>>({})

  // 获取VPS列表
  useEffect(() => {
    fetch('/api/vps').then(res => res.json()).then(setVpsList)
    fetch('/api/rates').then(res => res.json()).then(setRates)
  }, [])

  // 登录处理
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(loginForm)
    })
    if (res.ok) setIsLoggedIn(true)
  }

  // 添加VPS
  const handleAddVps = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const form = e.currentTarget
    const data = new FormData(form)
    const vps = Object.fromEntries(data.entries())
    
    const res = await fetch('/api/vps', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(vps)
    })

    if (res.ok) {
      setIsAdding(false)
      const newVps = await res.json()
      setVpsList(prev => [...prev, newVps])
    }
  }

  // 计算剩余价值
  const calculateValue = (vps: Vps) => {
    const now = new Date()
    const end = new Date(vps.endTime)
    const days = Math.max(0, (end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
    const value = (vps.price * days) / 365
    const cnyRate = rates[vps.currency] || 1
    return { value, valueCNY: value * cnyRate }
  }

  return (
    <main className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">VPS 价值追踪器</h1>
        {!isLoggedIn ? (
          <form onSubmit={handleLogin} className="flex gap-2">
            <input
              type="text"
              placeholder="用户名"
              value={loginForm.username}
              onChange={e => setLoginForm(prev => ({ ...prev, username: e.target.value }))}
              className="px-3 py-1 border rounded"
            />
            <input
              type="password"
              placeholder="密码"
              value={loginForm.password}
              onChange={e => setLoginForm(prev => ({ ...prev, password: e.target.value }))}
              className="px-3 py-1 border rounded"
            />
            <button type="submit" className="px-4 py-1 bg-blue-500 text-white rounded">
              登录
            </button>
          </form>
        ) : (
          <button
            onClick={() => setIsAdding(true)}
            className="px-4 py-2 bg-blue-500 text-white rounded"
          >
            添加 VPS
          </button>
        )}
      </div>

      {isAdding && (
        <form onSubmit={handleAddVps} className="mb-8 p-4 border rounded">
          <div className="grid grid-cols-2 gap-4">
            <input name="name" placeholder="商家名称" required className="px-3 py-2 border rounded" />
            <input name="cpu" placeholder="CPU (如: 2核 Intel)" required className="px-3 py-2 border rounded" />
            <input name="memory" type="number" placeholder="内存 (GB)" required className="px-3 py-2 border rounded" />
            <input name="disk" type="number" placeholder="硬盘 (GB)" required className="px-3 py-2 border rounded" />
            <input name="bandwidth" type="number" placeholder="流量 (GB)" required className="px-3 py-2 border rounded" />
            <div className="flex gap-2">
              <input name="price" type="number" step="0.01" placeholder="价格" required className="flex-1 px-3 py-2 border rounded" />
              <select name="currency" required className="px-3 py-2 border rounded">
                {['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY'].map(currency => (
                  <option key={currency} value={currency}>{currency}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex justify-end gap-2 mt-4">
            <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 border rounded">
              取消
            </button>
            <button type="submit" className="px-4 py-2 bg-blue-500 text-white rounded">
              添加
            </button>
          </div>
        </form>
      )}

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {vpsList.map(vps => {
          const { value, valueCNY } = calculateValue(vps)
          return (
            <div key={vps.id} className="p-4 border rounded">
              <h2 className="text-xl font-semibold mb-2">{vps.name}</h2>
              <div className="space-y-1 text-sm">
                <p>CPU: {vps.cpu}</p>
                <p>内存: {vps.memory}GB</p>
                <p>硬盘: {vps.disk}GB</p>
                <p>流量: {vps.bandwidth}GB</p>
                <p>价格: {vps.price} {vps.currency}</p>
                <p>到期时间: {formatDistanceToNow(new Date(vps.endTime), { locale: zhCN })}</p>
                <p className="font-semibold">
                  剩余价值: {value.toFixed(2)} {vps.currency}
                  <span className="text-gray-500 ml-2">
                    (≈ ¥{valueCNY.toFixed(2)})
                  </span>
                </p>
              </div>
            </div>
          )
        })}
      </div>
    </main>
  )
} 