<template>
    <Modal ref="modal" :category="{}" :isNew="true" @save="saveCategory" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modal = ref(null)

const emit = defineEmits(['save'])
defineExpose({ createNew })

function createNew() {
    modal.value.show()
}

function saveCategory(categoryData, done) {
    axios.post('/categories.json', { category: categoryData })
    done()
    emit('save')
}
</script>
