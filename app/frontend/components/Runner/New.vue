<template>
    <RunnerModal ref="modal" :runner="modalRunner" :isNew="true" @save="saveRunner" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import RunnerModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalRunner = ref({})
const modal = ref(null)

function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveRunner(runnerData, done) {
    axios.post('/runners.json', { runner: runnerData }).then(res => {
        window.location = "/runners?sorting[direction]=desc";
    })
}
</script>
