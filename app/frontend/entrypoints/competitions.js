import { createApp } from 'vue'
import Index from '../components/Competition/Index.vue'
import Show from '../components/Competition/Show.vue'
import New from '../components/Competition/New.vue'
import NewRunners from '../components/Competition/NewRunners.vue'
import EcnRanking from '../components/Competition/EcnRanking.vue'


function mountIfExists(id, component) {
  const el = document.getElementById("competitions_" + id)
  if (el) createApp(component).mount(el)
}

document.addEventListener('DOMContentLoaded', () => {
  mountIfExists('index', Index)
  mountIfExists('show', Show)
  mountIfExists('new', New)
  mountIfExists('new_runners', NewRunners)
  mountIfExists('ecn_ranking', EcnRanking)
})
