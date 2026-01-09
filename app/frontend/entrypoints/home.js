import { createApp } from 'vue'
import HomePage from '../components/Index/Home.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('home_index')
  if (el_index) {
    createApp(HomePage).mount(el_index)
  }
})

