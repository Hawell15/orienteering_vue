import { createApp } from 'vue'
import Index from '../components/Result/Index.vue'
import Show from '../components/Result/Show.vue'
import New from '../components/Result/New.vue'

function mountIfExists(id, component) {
  const el = document.getElementById("results_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
})
