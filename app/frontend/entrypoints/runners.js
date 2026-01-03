import { createApp } from 'vue'
import RunnersIndex from '../components/Runner/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('runners_index')
  if (el_index) {
    createApp(RunnersIndex).mount(el_index)
  }
})
