'use client'

import { useEffect, useState } from 'react'
import { formatDistance } from 'date-fns'
import { zh } from 'date-fns/locale'

interface Vps {
  id: number
  name: string
  cpuCores: number
  cpuModel: string
  memory: number
  disk: number
  bandwidth: number
  price: number
  currency: string
  startTime: string
  endTime: string
  remainingValue: number
  remainingValueCNY: number
}

export function VpsList() {
  const [vpsList, setVpsList] = useState<Vps[]>([])

  useEffect(() => {
    fetch('/api/vps')
      .then(res => res.json())
      .then(data => setVpsList(data))
  }, [])

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {vpsList.map(vps => (
        <div key={vps.id} className="p-4 border rounded-lg shadow-sm">
          <h2 className="text-xl font-semibold mb-2">{vps.name}</h2>
          <div className="space-y-2 text-sm">
            <p>CPU: {vps.cpuCores}核 ({vps.cpuModel})</p>
            <p>内存: {vps.memory}GB</p>
            <p>硬盘: {vps.disk}GB</p>
            <p>流量: {vps.bandwidth}GB</p>
            <p>价格: {vps.price} {vps.currency}</p>
            <p>到期时间: {formatDistance(new Date(vps.endTime), new Date(), { locale: zh })}</p>
            <p className="font-semibold">
              剩余价值: {vps.remainingValue.toFixed(2)} {vps.currency}
              <span className="text-gray-500 ml-2">
                (≈ ¥{vps.remainingValueCNY.toFixed(2)})
              </span>
            </p>
          </div>
        </div>
      ))}
    </div>
  )
} 