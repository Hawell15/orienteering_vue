import { createApp } from 'vue'
import GroupsIndex from '../components/Group/Index.vue'
import GroupsShow from '../components/Group/Show.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('groups_index')
  if (el_index) {
    createApp(GroupsIndex).mount(el_index)
  }
})

document.addEventListener('DOMContentLoaded', () => {
  const el_show = document.getElementById('groups_show')
  if (el_show) {
    createApp(GroupsShow).mount(el_show)
  }
})
