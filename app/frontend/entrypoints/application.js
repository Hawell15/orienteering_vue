import { createApp } from 'vue'
import App from '../components/App.vue'

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(App)
  app.mount('#app')
})
