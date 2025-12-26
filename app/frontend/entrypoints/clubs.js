import { createApp } from 'vue'
import ClubsIndex from '../components/Club/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('clubs_index')
  if (el_index) {
    createApp(ClubsIndex).mount(el_index)
  }
})
