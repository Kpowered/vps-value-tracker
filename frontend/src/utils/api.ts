import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL
})

// 请求拦截器
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 响应拦截器
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export interface VPS {
  id?: string
  provider: string
  price: number
  currency: string
  startDate: string
  endDate: string
  specs: string
}

export const vpsApi = {
  list: () => api.get<VPS[]>('/vps'),
  create: (vps: VPS) => api.post<VPS>('/vps', vps),
  update: (id: string, vps: VPS) => api.put(`/vps/${id}`, vps),
  delete: (id: string) => api.delete(`/vps/${id}`)
}

export const authApi = {
  login: (username: string, password: string) =>
    api.post<{ token: string }>('/login', { username, password })
}

export default api 