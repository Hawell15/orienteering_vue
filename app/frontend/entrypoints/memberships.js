import { createApp } from 'vue'
import MembershipsIndex from '../components/Membership/Index.vue'
import MembershipsShow from '../components/Membership/Show.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('memberships_index')
  if (el_index) {
    createApp(MembershipsIndex).mount(el_index)
  }
})

document.addEventListener('DOMContentLoaded', () => {
  const el_show = document.getElementById('memberships_show')
  if (el_show) {
    createApp(MembershipsShow).mount(el_show)
  }
})
