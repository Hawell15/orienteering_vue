<template>
    <CategoryModal ref="modal" :category="modalCategory" :isNew="true" @save="saveCategory" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import CategoryModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalCategory = ref({
    category_name: '',
    full_name: '',
    points: 0,
    validaty_period: 2,
    runners_count: 0,
    results_count: 0
})
const modal = ref(null)

function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveCategory(categoryData, done) {
    axios.post('/categories.json', { category: categoryData }).then(res => {
        window.location = "/categories?sorting[direction]=desc";
    })
}
</script>
