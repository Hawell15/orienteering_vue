import { createApp } from 'vue'
import Index from '../components/Club/Index.vue'
import Show from '../components/Club/Show.vue'
import New from '../components/Club/New.vue'


function mountIfExists(id, component) {
  const el = document.getElementById("clubs_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
})
