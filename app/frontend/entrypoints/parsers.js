import { createApp } from 'vue'
import Index from '../components/Parser/Index.vue'
import File from '../components/Parser/File.vue'

function mountIfExists(id, component) {
  const el = document.getElementById("parsers_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('file', File)
})
