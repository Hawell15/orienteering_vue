import { createApp } from 'vue'
import ResultsIndex from '../components/Result/Index.vue'
import ResultsShow from '../components/Result/Show.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('results_index')
  if (el_index) {
    createApp(ResultsIndex).mount(el_index)
  }
})

document.addEventListener('DOMContentLoaded', () => {
  const el_show = document.getElementById('results_show')
  if (el_show) {
    createApp(ResultsShow).mount(el_show)
  }
})

