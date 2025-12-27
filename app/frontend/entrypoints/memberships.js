import { createApp } from 'vue'
import MembershipsIndex from '../components/Membership/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('memberships_index')
  if (el_index) {
    createApp(MembershipsIndex).mount(el_index)
  }
})
