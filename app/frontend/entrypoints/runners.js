import { createApp } from 'vue'
import Index from '../components/Runner/Index.vue'
import Show from '../components/Runner/Show.vue'
// import New from '../components/Runner/New.vue'

function mountIfExists(id, component) {
  const el = document.getElementById("runners_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  // mountIfExists('new', New)
})
