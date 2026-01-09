import { createApp } from 'vue'
import ClubsIndex from '../components/Club/Index.vue'
import ClubsShow from '../components/Club/Show.vue'
import ClubsNew from '../components/Club/New.vue'


document.addEventListener('DOMContentLoaded', () => {
    const el_index = document.getElementById('clubs_index')
    if (el_index) {
        createApp(ClubsIndex).mount(el_index)
    }

    const el_show = document.getElementById('clubs_show')
    if (el_show) {
        createApp(ClubsShow).mount(el_show)
    }

    const el_new = document.getElementById('clubs_new')
    if (el_new) {
        createApp(ClubsNew).mount(el_new)
    }
})
