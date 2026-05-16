<template>
    <Modal ref="modal" :club="modalElement" :isNew="true" @save="saveElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const modal = ref(null)
const modalElement = ref({})

const emit = defineEmits(['save'])
defineExpose({ createNew })

function createNew() {
    modalElement.value = {}
    modal.value.show()
}

function saveElement(elementData, done) {
    axios.post('/clubs.json', { club: elementData })
    done()
    emit('save')
}
</script>
