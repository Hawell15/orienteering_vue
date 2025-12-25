import { createApp } from 'vue'
import CategoriesIndex from '../components/Category/Index.vue'

document.addEventListener('DOMContentLoaded', () => {
  const el_index = document.getElementById('categories_index')
  if (el_index) {
    createApp(CategoriesIndex).mount(el_index)
  }
})
