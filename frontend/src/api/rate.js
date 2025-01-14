import axios from 'axios';

const api = axios.create({
  baseURL: '/api'
});

export const rateAPI = {
  async getLatest() {
    const { data } = await api.get('/rates');
    return data;
  }
}; 