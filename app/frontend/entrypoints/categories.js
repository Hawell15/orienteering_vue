import { createApp } from 'vue'
import CategoriesIndex from '../components/Category/Index.vue'
import CategoriesShow from '../components/Category/Show.vue'
import CategoriesNew from '../components/Category/New.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('categories_index')
  if (el_index) {
    createApp(CategoriesIndex).mount(el_index)
  }

  const el_show = document.getElementById('categories_show')
  if (el_show) {
    createApp(CategoriesShow).mount(el_show)
  }

  const el_new = document.getElementById('categories_new')
  if (el_new) {
    createApp(CategoriesNew).mount(el_new)
  }
})

