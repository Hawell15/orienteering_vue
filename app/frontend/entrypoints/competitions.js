import { createApp } from 'vue'
import CompetitionsIndex from '../components/Competition/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('competitions_index')
  if (el_index) {
    createApp(CompetitionsIndex).mount(el_index)
  }
})
