import { createApp } from 'vue'
import Index from '../components/Category/Index.vue'
import Show from '../components/Category/Show.vue'
import New from '../components/Category/New.vue'

function mountIfExists(id, component) {
  const el = document.getElementById("categories_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
})
