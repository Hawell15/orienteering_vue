<template>
    <Modal ref="modal" :category="modalElement" :isNew="true" @save="saveCategory" />
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

function saveCategory(categoryData, done) {
    axios.post('/categories.json', { category: categoryData })
    done()
    emit('save')
}
</script>
