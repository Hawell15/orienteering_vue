<template>
    <RunnerModal ref="modal" :result="modalResult" :isNew="true" @save="saveResult" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import RunnerModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalResult = ref({})
const modal = ref(null)

function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveResult(resultData, done) {
    axios.post('/results.json', { result: resultData }).then(res => {
        window.location = "/results?sorting[direction]=desc";
    })
}
</script>
