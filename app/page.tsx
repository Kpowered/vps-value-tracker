import { VpsList } from '@/components/vps-list'

export default function Home() {
  return (
    <main className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">VPS 价值追踪器</h1>
      <VpsList />
    </main>
  )
} 