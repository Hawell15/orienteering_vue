import { createApp } from 'vue'
import RunnersIndex from '../components/Runner/Index.vue'
import RunnersShow from '../components/Runner/Show.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('runners_index')
  if (el_index) {
    createApp(RunnersIndex).mount(el_index)
  }
})

document.addEventListener('DOMContentLoaded', () => {
  const el_show = document.getElementById('runners_show')
  if (el_show) {
    createApp(RunnersShow).mount(el_show)
  }
})
