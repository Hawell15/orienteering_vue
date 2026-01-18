<template>
    <CompetitionModal ref="modal" :competition="modalCompetition" :isNew="true" @save="saveCompetition" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import CompetitionModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalCompetition = ref({
    competition_name: ''
})
const modal = ref(null)


function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveCompetition(competitionbData, done) {
    axios.post('/competitions.json', { competition: competitionbData }).then(res => {
        window.location = "/competitions?sorting[direction]=desc";
    })
}
</script>
