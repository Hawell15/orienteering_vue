<template>
    <Modal ref="modal" :competition="modalElement" :isNew="true" @save="saveElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modal = ref(null)
const modalElement = ref({})

const emit = defineEmits(['save'])
defineExpose({ createNew })

function createNew() {
    modalElement.value = {}
    modal.value.show()
}

function saveElement(elementData, done) {
    axios.post('/competitions.json', { competition: elementData })
    done()
    emit('save')
}
</script>
