import { createApp } from 'vue'
import Index from '../components/Membership/Index.vue'
import Show from '../components/Membership/Show.vue'
import New from '../components/Membership/New.vue'

function mountIfExists(id, component) {
  const el = document.getElementById("memberships_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
})

