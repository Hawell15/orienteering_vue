<template>
    <Modal ref="modal" :result="modalElement" :isNew="true" @save="saveElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const modal = ref(null)
const modalElement = ref({})

const emit = defineEmits(['save'])
defineExpose({ createNew })

function createNew(initial = {}) {
    modalElement.value = { ...initial }
    modal.value.show()
}

async function saveElement(elementData, done) {
    await axios.post('/results.json', { result: elementData })
    done()
    emit('save')
}
</script>
