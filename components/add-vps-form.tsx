'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

interface AddVpsFormProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

const currencies = ['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY'] as const
type Currency = typeof currencies[number]

export function AddVpsForm({ open, onOpenChange }: AddVpsFormProps) {
  const router = useRouter()
  const [formData, setFormData] = useState({
    name: '',
    cpuCores: 1,
    cpuModel: '',
    memory: 1,
    disk: 20,
    bandwidth: 1000,
    price: 0,
    currency: 'CNY' as Currency,
  })
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    try {
      const res = await fetch('/api/vps', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!res.ok) {
        const data = await res.json()
        throw new Error(data.error || '添加失败')
      }

      onOpenChange(false)
      router.refresh()
      setFormData({
        name: '',
        cpuCores: 1,
        cpuModel: '',
        memory: 1,
        disk: 20,
        bandwidth: 1000,
        price: 0,
        currency: 'CNY',
      })
    } catch (err) {
      setError(err instanceof Error ? err.message : '添加失败')
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <h2 className="text-2xl font-bold mb-4">添加 VPS</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="text-red-500 text-sm">{error}</div>
          )}
          
          <div>
            <label className="block text-sm font-medium mb-1">商家名称</label>
            <input
              type="text"
              required
              className="w-full px-3 py-2 border rounded-md"
              value={formData.name}
              onChange={e => setFormData(prev => ({ ...prev, name: e.target.value }))}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">CPU 核心数</label>
              <input
                type="number"
                required
                min="1"
                className="w-full px-3 py-2 border rounded-md"
                value={formData.cpuCores}
                onChange={e => setFormData(prev => ({ ...prev, cpuCores: parseInt(e.target.value) }))}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">CPU 型号</label>
              <input
                type="text"
                required
                className="w-full px-3 py-2 border rounded-md"
                value={formData.cpuModel}
                onChange={e => setFormData(prev => ({ ...prev, cpuModel: e.target.value }))}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">内存 (GB)</label>
              <input
                type="number"
                required
                min="1"
                className="w-full px-3 py-2 border rounded-md"
                value={formData.memory}
                onChange={e => setFormData(prev => ({ ...prev, memory: parseInt(e.target.value) }))}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">硬盘 (GB)</label>
              <input
                type="number"
                required
                min="1"
                className="w-full px-3 py-2 border rounded-md"
                value={formData.disk}
                onChange={e => setFormData(prev => ({ ...prev, disk: parseInt(e.target.value) }))}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">流量 (GB)</label>
              <input
                type="number"
                required
                min="1"
                className="w-full px-3 py-2 border rounded-md"
                value={formData.bandwidth}
                onChange={e => setFormData(prev => ({ ...prev, bandwidth: parseInt(e.target.value) }))}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">价格</label>
              <div className="flex gap-2">
                <input
                  type="number"
                  required
                  min="0"
                  step="0.01"
                  className="flex-1 px-3 py-2 border rounded-md"
                  value={formData.price}
                  onChange={e => setFormData(prev => ({ ...prev, price: parseFloat(e.target.value) }))}
                />
                <select
                  className="px-3 py-2 border rounded-md"
                  value={formData.currency}
                  onChange={e => setFormData(prev => ({ ...prev, currency: e.target.value as Currency }))}
                >
                  {currencies.map(currency => (
                    <option key={currency} value={currency}>
                      {currency}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-4 mt-6">
            <button
              type="button"
              onClick={() => onOpenChange(false)}
              className="px-4 py-2 border rounded-md hover:bg-gray-50"
            >
              取消
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              添加
            </button>
          </div>
        </form>
      </div>
    </div>
  )
} 