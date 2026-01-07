import { createApp } from 'vue'
import CategoriesIndex from '../components/Category/Index.vue'
import CategoriesShow from '../components/Category/Show.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('categories_index')
  if (el_index) {
    createApp(CategoriesIndex).mount(el_index)
  }
})

document.addEventListener('DOMContentLoaded', () => {
  const el_show = document.getElementById('categories_show')
  if (el_show) {
    createApp(CategoriesShow).mount(el_show)
  }
})

