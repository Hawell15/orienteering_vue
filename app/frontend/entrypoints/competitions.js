import { createApp } from 'vue'
import Index from '../components/Competition/Index.vue'
import Show from '../components/Competition/Show.vue'
import New from '../components/Competition/New.vue'
import EcnCoeficients from '../components/Competition/EcnCoeficients.vue'


function mountIfExists(id, component) {
  const el = document.getElementById("competitions_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
  mountIfExists('ecn_coeficients', EcnCoeficients)
})
