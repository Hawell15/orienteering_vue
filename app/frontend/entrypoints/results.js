import { createApp } from 'vue'
import ResultsIndex from '../components/Result/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('results_index')
  if (el_index) {
    createApp(ResultsIndex).mount(el_index)
  }
})
