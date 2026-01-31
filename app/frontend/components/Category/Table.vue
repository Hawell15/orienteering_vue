<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('category_name')">Nume</th>
                <th @click="orderTable('full_name')">Nume Complet</th>
                <th @click="orderTable('points')">Puncte</th>
                <th @click="orderTable('validaty_period')">Validitate(Ani)</th>
                <th @click="orderTable('runners_count')">Numar Sportivi</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
         <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`categories/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`categories/${element.id}`">{{ element.category_name }}</a></td>
                <td><a :href="`categories/${element.id}`">{{ element.full_name }}</a></td>
                <td>{{ element.points }}</td>
                <td>{{ element.validaty_period }}</td>
                <td>
                    <a :href="`/runners?category_id=${element.id}`">
                        {{ element.runners_count }}
                    </a>
                </td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`categories/${element.id}`">
                        Arată
                    </a>
                </td>
                <td>
                    <button class="btn btn-sm btn-success" @click="editElement(element)">
                        Editează
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                        Șterge
                    </button>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :category="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const props = defineProps({
  elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi această categorie?')) {
        axios.delete(`/categories/${id}`).then(() => {
            props.elements = props.elements.filter(category => category.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/categories/${elementData.id}.json`, { category: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}


</script>
