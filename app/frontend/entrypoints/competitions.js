import { createApp } from 'vue'
import CompetitionsIndex from '../components/Competition/Index.vue'
import CompetitionsShow from '../components/Competition/Show.vue'
import CompetitionsNew from '../components/Competition/New.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('competitions_index')
  if (el_index) {
    createApp(CompetitionsIndex).mount(el_index)
  }

  const el_show = document.getElementById('competitions_show')
  if (el_show) {
    createApp(CompetitionsShow).mount(el_show)
  }

  const el_new = document.getElementById('competitions_new')
  if (el_new) {
    createApp(CompetitionsNew).mount(el_new)
  }
})
