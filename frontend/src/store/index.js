import { createStore } from 'vuex';
import { authAPI } from '../api/auth';

export default createStore({
  state: {
    token: localStorage.getItem('token') || '',
    user: JSON.parse(localStorage.getItem('user') || 'null'),
    isLoggedIn: !!localStorage.getItem('token')
  },

  mutations: {
    SET_TOKEN(state, token) {
      state.token = token;
      state.isLoggedIn = !!token;
      localStorage.setItem('token', token);
    },

    SET_USER(state, user) {
      state.user = user;
      localStorage.setItem('user', JSON.stringify(user));
    },

    CLEAR_AUTH(state) {
      state.token = '';
      state.user = null;
      state.isLoggedIn = false;
      localStorage.removeItem('token');
      localStorage.removeItem('user');
    }
  },

  actions: {
    async login({ commit }, credentials) {
      try {
        const { token, user } = await authAPI.login(credentials);
        commit('SET_TOKEN', token);
        commit('SET_USER', user);
      } catch (error) {
        throw new Error('登录失败，请检查用户名和密码');
      }
    },

    logout({ commit }) {
      commit('CLEAR_AUTH');
    }
  }
}); 