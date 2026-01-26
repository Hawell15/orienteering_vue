import { createApp } from 'vue'
import GroupsIndex from '../components/Group/Index.vue'
import GroupsShow from '../components/Group/Show.vue'
import GroupsNew from '../components/Group/New.vue'

function mountIfExists(id, component) {
  const el = document.getElementById(id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('groups_index', GroupsIndex)
  mountIfExists('groups_show', GroupsShow)
  mountIfExists('groups_new', GroupsNew)
})
