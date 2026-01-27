import { createApp } from 'vue'
import Index from '../components/Group/Index.vue'
import Show from '../components/Group/Show.vue'
import New from '../components/Group/New.vue'

function mountIfExists(id, component) {
  const el = document.getElementById("groups_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
})
