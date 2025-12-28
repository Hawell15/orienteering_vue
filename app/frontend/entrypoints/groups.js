import { createApp } from 'vue'
import GroupsIndex from '../components/Group/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('groups_index')
  if (el_index) {
    createApp(GroupsIndex).mount(el_index)
  }
})
