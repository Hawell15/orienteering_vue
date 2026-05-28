import { createApp } from 'vue'
import App from '../components/App.vue'
import AdminBar from '../components/Index/AdminBar.vue'
import '../stylesheets/layout.css'
import '../stylesheets/devise.css'

document.addEventListener('DOMContentLoaded', () => {
  createApp(App).mount('#app')
  const adminBarEl = document.getElementById('admin-bar')
  if (adminBarEl) createApp(AdminBar).mount(adminBarEl)
})
