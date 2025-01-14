import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../utils/api'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token'))
  const isAuthenticated = ref(!!token.value)

  const login = async (username: string, password: string) => {
    try {
      const { data } = await api.post('/auth/login', { username, password })
      token.value = data.token
      localStorage.setItem('token', data.token)
      isAuthenticated.value = true
      return true
    } catch (error) {
      return false
    }
  }

  const logout = () => {
    token.value = null
    localStorage.removeItem('token')
    isAuthenticated.value = false
  }

  return {
    token,
    isAuthenticated,
    login,
    logout
  }
}) 