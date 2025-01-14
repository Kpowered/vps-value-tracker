import axios from 'axios';

const api = axios.create({
  baseURL: '/api'
});

export const vpsAPI = {
  async getAll() {
    const { data } = await api.get('/vps');
    return data;
  },

  async create(vpsData) {
    const { data } = await api.post('/vps', vpsData, {
      headers: {
        Authorization: `Bearer ${localStorage.getItem('token')}`
      }
    });
    return data;
  },

  async delete(id) {
    await api.delete(`/vps/${id}`, {
      headers: {
        Authorization: `Bearer ${localStorage.getItem('token')}`
      }
    });
  },

  async update(id, vpsData) {
    const { data } = await api.put(`/vps/${id}`, vpsData, {
      headers: {
        Authorization: `Bearer ${localStorage.getItem('token')}`
      }
    });
    return data;
  }
}; 