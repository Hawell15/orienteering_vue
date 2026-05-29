<template>
    <Modal ref="modal" :relayResult="modalElement" :isNew="isNew" @save="saveElement" />
</template>

<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'

const modal        = ref(null)
const modalElement = ref({})
const isNew        = ref(true)

const emit = defineEmits([ 'save' ])
defineExpose({ createNew, editExisting })

function createNew(initial = {}) {
    modalElement.value = { ...initial }
    isNew.value = true
    modal.value.show()
}

function editExisting(relay) {
    modalElement.value = { ...relay }
    isNew.value = false
    modal.value.show()
}

async function saveElement(payload, done) {
    if (payload.id) {
        await axios.patch(`/relay_results/${payload.id}.json`, { relay_result: payload })
    } else {
        await axios.post('/relay_results.json', { relay_result: payload })
    }
    done()
    emit('save')
}
</script>
