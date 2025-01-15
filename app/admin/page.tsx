'use client'

import { useState } from 'react'
import { AddVpsForm } from '@/components/add-vps-form'

export default function AdminPage() {
  const [isFormOpen, setIsFormOpen] = useState(false)

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">VPS 管理</h1>
        <button
          onClick={() => setIsFormOpen(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          添加 VPS
        </button>
      </div>
      <AddVpsForm open={isFormOpen} onOpenChange={setIsFormOpen} />
    </div>
  )
} 